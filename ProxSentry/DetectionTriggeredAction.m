//
//  ScreenActionController.m
//  ProxSentry
//
/*
	https://https://github.com/peteburtis/ProxSentry

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

#import "DetectionTriggeredAction.h"
#import "FaceDetectionController.h"

@interface DetectionTriggeredAction ()
@property (strong) NSTimer *faceExitTriggerDelayTimer;
@end

@implementation DetectionTriggeredAction

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
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(px_faceEnteredNotification:)
                                                     name:FaceDidEnterCameraFieldOfViewNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(px_faceExitedNotification:)
                                                     name:FaceDidExitCameraFieldOfViewNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(px_detectionDidDisableNotification:)
                                                     name:FaceDetectionDidDisableNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(px_detectionWillEnableNotification:)
                                                     name:FaceDetectionWillEnableNotification
                                                   object:nil];
    }
    return self;
}

#pragma mark - Notifications

/*
 Because this class is explicitly designed to be overridden to make hacking on this app easier, prefix private methods with px_ so they aren't accidentally overridden by subclasses.
*/

-(void)px_detectionDidDisableNotification:(NSNotification *)notification
{
    [_faceExitTriggerDelayTimer invalidate];
    _faceExitTriggerDelayTimer = nil;
    
    [self faceDetectionDidDisable];
}

-(void)px_detectionWillEnableNotification:(NSNotification *)notification
{
    [self faceDetectionWillEnable];
}

-(void)px_faceEnteredNotification:(NSNotification *)notification
{
    [_faceExitTriggerDelayTimer invalidate];
    _faceExitTriggerDelayTimer = nil;
 
    if ( ! self.facesPresent ) {
        /*
         If we show faces present even though we got a face entered notification, that means the face exit timer hasn't fired yet, and faceDidExitCameraFieldOfView hasn't been called yet.  Invalidating the timer and doing nothing else is correct.
        */
        
        [self willChangeValueForKey:@"facesPresent"];
        _facesPresent = YES;
        [self didChangeValueForKey:@"facesPresent"];
        
        [self faceDidEnterCameraFieldOfView];
    }
}

-(void)px_faceExitedNotification:(NSNotification *)notification
{
    [self faceExitDelayTimerWillStart]; // Allows child objects to change the delay time if they wish.

    if (_faceExitTriggerDelay != 0) {
        
        /*
         Theoretically, there should never be a timer active at this point because we should never receive two exit notifications 
         without an enter notification between them, but cover all the bases anyway.
        */
        if ( ! _faceExitTriggerDelayTimer ) {
            _faceExitTriggerDelayTimer = [NSTimer scheduledTimerWithTimeInterval:_faceExitTriggerDelay
                                                                          target:self
                                                                        selector:@selector(px_faceExitedDelayTimerFired:)
                                                                        userInfo:nil
                                                                         repeats:NO];
        }
        
    } else {
        [self willChangeValueForKey:@"facesPresent"];
        _facesPresent = NO;
        [self didChangeValueForKey:@"facesPresent"];
        
        [self faceDidExitCameraFieldOfView];
    }
}

-(void)px_faceExitedDelayTimerFired:(NSTimer *)timer
{
    [self willChangeValueForKey:@"facesPresent"];
    _facesPresent = NO;
    [self didChangeValueForKey:@"facesPresent"];
    
    [self faceDidExitCameraFieldOfView];
    _faceExitTriggerDelayTimer = nil;
}

#pragma mark - Accessors

-(BOOL)facesPresent
{
    return _facesPresent;
}

#pragma mark - Abstract Functions
/*
 These functions exist only to be overridden by subclasses.
*/

-(void)faceDetectionWillEnable {}
-(void)faceDetectionDidDisable {}

-(void)faceDidEnterCameraFieldOfView {}
-(void)faceDidExitCameraFieldOfView {}

-(void)faceExitDelayTimerWillStart {}

@end
