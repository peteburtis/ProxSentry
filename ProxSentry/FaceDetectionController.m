//
//  CaptureController.m
//  ProxSentry
//
/*
	https://github.com/peteburtis/ProxSentry

    Copyright (C) 2012 Peter Burtis

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#import "FaceDetectionController.h"
#import "FaceOutlineDrawingLayer.h"


/* FaceDetectionControllerWillNotifyFaceDidEntere is nessecary to wake the screen when it is sleeping before performing the rest of the face entry stuff. It probably shouldn't be used for anything else.
 */
NSString * const FaceDetectionControllerWillNotifyFaceDidEnter = @"FaceDetectionControllerWillNotifyFaceDidEnter";
NSString * const FaceDidEnterCameraFieldOfViewNotification = @"FaceDidEnterCameraFieldOfViewNotification";
NSString * const FaceDidExitCameraFieldOfViewNotification = @"FaceDidExitCameraFieldOfViewNotification";

NSString * const FaceDetectionWillEnableNotification = @"FaceDetectionWillEnableNotification";
NSString * const FaceDetectionDidDisableNotification = @"FaceDetectionDisableNotification";

NSString * const FaceDetectionEnabledStateDidChangeNotification = @"FaceDetectionEnabledStateDidChangeNotification";

NSString * const LowerWebcamResolution = @"LowerWebcamResolution";

@interface FaceDetectionController ()
@property (strong) AVCaptureDevice *webcamDevice;
@property (strong) AVCaptureDeviceInput *webcamDeviceInput;
@property (strong) AVCaptureSession *session;
@property (strong) AVCaptureVideoDataOutput *dataOutput;
@property (strong) CIDetector *faceDetector;

@property (weak) AVCaptureVideoPreviewLayer *videoLayer;
@property (weak) FaceOutlineDrawingLayer *outlineLayer;
@property (strong) CALayer *previewSuperlayer;
@end

@implementation FaceDetectionController


+(BOOL)automaticallyNotifiesObserversForKey:(NSString *)theKey {
    if ([theKey isEqualToString:@"facesPresent"]) {
        return NO;
    }
    return YES;
}

-(id)init
{
    self = [super init];
    if (self) {
        _faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace
                                           context:nil
                                           options:@{CIDetectorAccuracy:CIDetectorAccuracyLow}];
    }
    return self;
}

-(void)updateFaces:(NSArray *)faces
{
    BOOL newFacesPresent = (faces.count > 0);
    if (newFacesPresent != _facesPresent) {
        [self willChangeValueForKey:@"facesPresent"];
        _facesPresent = newFacesPresent;
        [self didChangeValueForKey:@"facesPresent"];
        
        if (self.enabled) {
            NSString *notificationName = nil;
            if (_facesPresent) {
                [[NSNotificationCenter defaultCenter] postNotificationName:FaceDetectionControllerWillNotifyFaceDidEnter object:self];
                notificationName = FaceDidEnterCameraFieldOfViewNotification;
            } else {
                notificationName = FaceDidExitCameraFieldOfViewNotification;
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:self];
        }
    }
    self.outlineLayer.faces = faces;
}

-(void)buildCaptureSession
{    
    if (_session) return;

    NSError *error = nil;
    
    _webcamDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (! _webcamDevice) {
        // TODO UI ERROR
        NSLog(@"No Default Video Device.");
        return;
    }
    
    [_webcamDevice addObserver:self
                    forKeyPath:@"activeFormat"
                       options:0
                       context:NULL];
    
    BOOL hasLock = NO;
    if ( ! [_webcamDevice isInUseByAnotherApplication] && [[NSUserDefaults standardUserDefaults] boolForKey:LowerWebcamResolution]) {
        NSError *error = nil;
        [_webcamDevice lockForConfiguration:&error];
        if ( ! error) {
            hasLock = NO;
            
            NSArray *formats = [_webcamDevice formats];
            NSLog(@"Webcam supports formats:\n%@", formats);
            
            for (AVCaptureDeviceFormat *format in formats) {
                CMFormatDescriptionRef formatDescription = format.formatDescription;
                CGSize resolution = CMVideoFormatDescriptionGetPresentationDimensions(formatDescription, true, true);
                
                if (resolution.width >= 320 && resolution.height >= 240) {
                    _webcamDevice.activeFormat = format;
                    NSLog(@"Selecting Resolution: %@", NSStringFromSize(NSSizeFromCGSize(resolution)) );
                    break;
                }
            }
            
        } else {
            NSLog(@"Couldn't configure camera; will attempt to use anyway. Error : %@", error);
        }
    }
    
    _webcamDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:_webcamDevice error:&error];
    if (!_webcamDeviceInput) {
        // TODO UI ERROR
        NSLog(@"Error accessing device input: %@", error);
        return;
    }
    
    _session = [AVCaptureSession new];
    [_session addInput:_webcamDeviceInput];
    
    
    _dataOutput = [AVCaptureVideoDataOutput new];
    _dataOutput.videoSettings = nil; // Setting to nil ensures uncompressed frames are given to us
    [_dataOutput setSampleBufferDelegate:self queue:dispatch_get_global_queue(0, 0)];
    [_session addOutput:_dataOutput];
    
    if (hasLock) {
        [self buildVideoPreviewLayer];  // Build the video preivew layer while we still have the device locked.
        [_webcamDevice unlockForConfiguration];
    }
}

-(void)destroyCaptureSession
{
    [_webcamDevice removeObserver:self forKeyPath:@"activeFormat"];
    
    _webcamDevice = nil;
    _webcamDeviceInput = nil;
    _session = nil;
    _dataOutput = nil;
}

-(void)buildVideoPreviewLayer
{
    [self buildCaptureSession];
    if (_previewSuperlayer != nil) return;
    
    // Create and configure the video preview layer
    AVCaptureVideoPreviewLayer *newPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSessionWithNoConnection:_session];
    newPreviewLayer.backgroundColor = [[NSColor blackColor] CGColor];
    
    // Connect the video preview layer to our capture session
    //        [newPreviewLayer setSessionWithNoConnection:_session];
    AVCaptureConnection *connection = [AVCaptureConnection connectionWithInputPort:_webcamDeviceInput.ports[0]
                                                                 videoPreviewLayer:newPreviewLayer];
    connection.automaticallyAdjustsVideoMirroring = NO;
    connection.videoMirrored = YES;
    [_session addConnection:connection];
    
    // Build a layer to hold the video preview layer and the face outline drawing layer on top of it
    _previewSuperlayer = [CALayer layer];
    newPreviewLayer.frame = _previewSuperlayer.bounds;
    newPreviewLayer.zPosition = 0;
    newPreviewLayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
    [_previewSuperlayer addSublayer:newPreviewLayer];
    
    
    // Build the face outline layer
    FaceOutlineDrawingLayer *outlineLayer = [FaceOutlineDrawingLayer layer];
    outlineLayer.frame = _previewSuperlayer.bounds;
    outlineLayer.zPosition = 1;
    outlineLayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
    [_previewSuperlayer addSublayer:outlineLayer];
    
    // Assign the new sublayers to their properties
    _videoLayer = newPreviewLayer;
    _outlineLayer = outlineLayer;
    
    [self setSourceFrameSize];
}

-(void)destroyVideoPreviewLayer
{
    _previewSuperlayer = nil;
    _videoLayer = nil;
    _outlineLayer = nil;
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == _webcamDevice) {
        [self setSourceFrameSize];
    }
}

#pragma mark - Public Methods

-(void)setEnabled:(BOOL)enabled
{
    @synchronized (self) {
        if (_enabled != enabled) {
            _enabled = enabled;
            
            if (_enabled) {
                [[NSNotificationCenter defaultCenter] postNotificationName:FaceDetectionWillEnableNotification
                                                                    object:self];
                
                [self buildCaptureSession];
                [_session startRunning];
                
            } else {
                [_session stopRunning];
                [[NSNotificationCenter defaultCenter] postNotificationName:FaceDetectionDidDisableNotification
                                                                    object:self];
                [self updateFaces:@[]];
            }
            
            
            [[NSNotificationCenter defaultCenter] postNotificationName:FaceDetectionEnabledStateDidChangeNotification
                                                                object:self];
        }
    }
}

-(BOOL)enabled
{
    @synchronized (self) {
        return _enabled;
    }
}

-(void)setActivationDisabledForSystemSleep:(BOOL)activationDisabledForSystemSleep
{
    if (activationDisabledForSystemSleep != _activationDisabledForSystemSleep) {
        _activationDisabledForSystemSleep = activationDisabledForSystemSleep;
        [self shutdownVideoCapture];
    }
}

-(CALayer *)videoPreviewLayer
{
    if (_previewSuperlayer == nil) {
        /*
            We go through the trouble of manually creating a connection here (instead of just adding the preview layer to the session in one line) so we can mirror the video seen by the user.
         */
        [self buildVideoPreviewLayer];
    }
    return self.previewSuperlayer;
}

-(void)shutdownVideoCapture
{
    self.enabled = NO;
    [self destroyCaptureSession];
    [self destroyVideoPreviewLayer];
}

#pragma mark - Video Control

-(void)setSourceFrameSize
{
    // Find the frame size of the webcam
    CMFormatDescriptionRef formatDescription = self.webcamDevice.activeFormat.formatDescription;
    CGSize videoDimensions = CMVideoFormatDescriptionGetPresentationDimensions(formatDescription, true, true);
    self.outlineLayer.sourceFrameSize = videoDimensions;
}



#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate methods

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if ( ! self.enabled ) return;
    
    /*
     Search the sampleBuffer (one frame of video) for faces using the faceDetector we created in awakeFromNib. AVFoundation calls this method from a secondary thread (a libdispatch queue, noless), so the main thread won't be blocked while we work.
    */
    
    // Only analize one frame out of every KEY_FRAME_INTERVAL (currently 15) frames
    // At some point this should be refactored to be time based (i.e., analyze one frame every 1.5 seconds or so)
    static int frameCounter = 1;
    if (frameCounter++ % KEY_FRAME_INTERVAL == 0)
        frameCounter = 1;
    else
        return;
    
    // Convert the image into a format our faceDetector can use
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CIImage *image = [[CIImage alloc] initWithCVImageBuffer:imageBuffer];
    
    NSArray *faces = [self.faceDetector featuresInImage:image];
    
    /*
     Update the main thread with the results of our face search.  We use dispatch_sync, which blocks this secondary thread until the main thread updates are finished, because AVFoundation drops any frames that come in while this secondary thread is blocked; there's no use analyzing more frames while we're still waiting for the current frame to be processed.
    */
    dispatch_sync(dispatch_get_main_queue(), ^{
        if (self.enabled) {
            [self updateFaces:faces];
        }
    });
}

@end
