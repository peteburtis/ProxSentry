//
//  CaptureController.h
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


#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#define KEY_FRAME_INTERVAL 15

// NSUserDefaults keys
extern NSString * const LowerWebcamResolution;


// Notifications
extern NSString * const FaceDidEnterCameraFieldOfViewNotification;
extern NSString * const FaceDidExitCameraFieldOfViewNotification;

extern NSString * const FaceDetectionWillEnableNotification;
extern NSString * const FaceDetectionDidDisableNotification;

extern NSString * const FaceDetectionEnabledStateDidChangeNotification;


@interface FaceDetectionController : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate> {
    @private
    BOOL _facesPresent, _enabled;
}

@property (atomic) BOOL enabled;
@property (nonatomic) BOOL activationDisabledForSystemSleep;
@property (nonatomic, readonly) BOOL facesPresent;

-(AVCaptureVideoPreviewLayer *)videoPreviewLayer;
-(void)uncachePreviewLayer;
-(void)shutdownVideoCapture;

@end
