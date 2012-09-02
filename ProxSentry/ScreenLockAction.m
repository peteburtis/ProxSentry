//
//  ScreenLockController.m
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

#import "ScreenLockAction.h"
#import "FaceDetectionController.h"

NSString * const LockScreen = @"LockScreen";
NSString * const LockMode = @"LockMode";
NSString * const LockDuration = @"LockDuration";
NSString * const UnlockScreen = @"UnlockScreen";

NSString * const ScreenLockActionWillForceSleepNotification = @"ScreenLockActionWillForceSleepNotification";

@implementation ScreenLockAction

-(void)faceExitDelayTimerWillStart
{
    /*
     Update the trigger delay immediatly before the timer starts.
    */
    self.faceExitTriggerDelay = [[[NSUserDefaults standardUserDefaults] objectForKey:LockDuration] doubleValue];
}

-(void)faceDidExitCameraFieldOfView
{
    if ( ! [[NSUserDefaults standardUserDefaults] boolForKey:LockScreen]) return;
    
    NSInteger lockMode = [[NSUserDefaults standardUserDefaults] integerForKey:LockMode];
    if (lockMode == 0) {
        
        // Invoke the proper command line voodoo to start the screensaver.
        [NSTask launchedTaskWithLaunchPath:@"/usr/bin/open" arguments:@[ @"-a", @"/System/Library/Frameworks/ScreenSaver.framework/Versions/A/Resources/ScreenSaverEngine.app" ]];
        
    } else if (lockMode == 1) {
        
        [[NSNotificationCenter defaultCenter] postNotificationName:ScreenLockActionWillForceSleepNotification
                                                            object:self];
        IOPMSleepSystem(IOPMFindPowerManagement(MACH_PORT_NULL));
        
    } else {
        
        // Invoke the proper command line voodoo to lock the screen. (i.e. cube out to the login prompt.)
        [NSTask launchedTaskWithLaunchPath:@"/System/Library/CoreServices/Menu Extras/User.menu/Contents/Resources/CGSession" arguments:@[ @"-suspend" ]];
        
    }

}

-(void)faceDidEnterCameraFieldOfView
{
    NSUInteger lockMode = [[NSUserDefaults standardUserDefaults] integerForKey:LockMode];
    BOOL unlockScreenPref = [[NSUserDefaults standardUserDefaults] integerForKey:UnlockScreen];
    if (lockMode == 0 && unlockScreenPref) {
        
        NSArray *screensaverEngineResults = [NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.apple.ScreenSaver.Engine"];
        
        if (screensaverEngineResults.count > 0) {
            [self stopScreensaver];
        }
        
    }
    
}

-(void)stopScreensaver
{
    static NSAppleScript *script = nil;
    if (!script) {
        script = [[NSAppleScript alloc] initWithSource:@"tell application \"System Events\" \n repeat with x in screen savers \n stop x \n end repeat \n end tell" ];
    }
    NSDictionary *error = nil;
    [script executeAndReturnError:&error];
    
    if (error) {
        NSLog(@"Error stopping screensaver with applescript: %@", error);
    }
}


@end
