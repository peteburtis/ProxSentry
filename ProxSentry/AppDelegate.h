//
//  AppDelegate.h
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

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>
#import <IOKit/pwr_mgt/IOPMLib.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/IOMessage.h>

#define HUD_WINDOW_FINAL_SIZE NSMakeSize( 280, 210 )

// NSUserDefaults keys
extern NSString * const AlwaysDisableCameraOnDisplaySleep;
extern NSString * const HUDWindowOpacity;
extern NSString * const HUDWindowDisableTitleBar;

@class FaceDetectionController;
@class BatteryPowerMonitor;
@class PowerStateOverrideHelperAction;

@interface AppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate> {
    @private
    BOOL needsRestartAfterSystemSleep, needsRestartAfterDisplaySleep;
}

@property (nonatomic, assign) IBOutlet NSWindow *window;
@property (nonatomic, assign) IBOutlet NSPanel *HUDWindow;
@property (nonatomic, assign) IBOutlet NSView *cameraView;
@property (nonatomic, assign) IBOutlet FaceDetectionController *faceDetectionController;
@property (nonatomic, assign) IBOutlet BatteryPowerMonitor *batteryPowerMonitor;
@property (nonatomic, assign) IBOutlet PowerStateOverrideHelperAction *powerHelper;

-(IBAction)showAboutPanel:(id)sender;
-(IBAction)showMainWindow:(id)sender;

@end
