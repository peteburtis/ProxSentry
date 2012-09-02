//
//  ScreenActionController.h
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

/*
 This is the abstract superclass for all actions that happen when a face is seen entering or exiting the camera field of view. Subclasses override faceDidEnterCameraFieldOfView and faceDidExitCameraFieldOfView to act on face detection.
 
 The faceExitTriggerDelay property, when set to a non-zero value, will delay the calling of faceDidExitCameraFieldOfView until _n_ seconds pass.
 
 The faceExitDelayTimerWillStart method can be overridden and used to set faceExitTriggerDelay immediatly before it is started.
*/

#import <Foundation/Foundation.h>

@interface DetectionTriggeredAction : NSObject {
    BOOL _facesPresent, _faceDetectionEnabled;
}

@property NSTimeInterval faceExitTriggerDelay;
@property (readonly) BOOL facesPresent;
@property (readonly) BOOL faceDetectionEnabled;

// Abstract methods for subclasses to override

-(void)faceDetectionWillEnable;
-(void)faceDetectionDidDisable;

-(void)faceDidEnterCameraFieldOfView;
-(void)faceDidExitCameraFieldOfView;

-(void)faceExitDelayTimerWillStart;

@end
