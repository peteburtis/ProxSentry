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
NSString * const ExitScreensaverBySimulatingKeystroke = @"ExitScreensaverBySimulatingKeystroke";
NSString * const AlternateScreensaverApplicationBundleIdentifier = @"AlternateScreensaverApplicationBundleIdentifier";

NSString * const ScreenLockActionWillForceSleepNotification = @"ScreenLockActionWillForceSleepNotification";

@interface ScreenLockAction ()
@property (nonatomic, strong) NSString *runningAlternateScreensaverBundleID;
@end

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
        
        [self startScreensaver];
        
    } else if (lockMode == 1) {
        
        [[NSNotificationCenter defaultCenter] postNotificationName:ScreenLockActionWillForceSleepNotification
                                                            object:self];
        IOPMSleepSystem(IOPMFindPowerManagement(MACH_PORT_NULL));
        
    } else {
        
        // Invoke the proper command line voodoo to lock the screen. (i.e. cube out to the login prompt.)
        [NSTask launchedTaskWithLaunchPath:PATH_TO_LOCK_UTILITY arguments:LOCK_UTILITY_ARGUMENS];
        
    }

}

-(void)faceDidEnterCameraFieldOfView
{
    NSUInteger lockMode = [[NSUserDefaults standardUserDefaults] integerForKey:LockMode];
    BOOL unlockScreenPref = [[NSUserDefaults standardUserDefaults] integerForKey:UnlockScreen];
    if (lockMode == 0 && unlockScreenPref) {
        [self stopScreensaver];
    }
    
}

-(void)startScreensaver
{
    NSString *alternateScreensaverID = [[NSUserDefaults standardUserDefaults] stringForKey:AlternateScreensaverApplicationBundleIdentifier];
    NSString *screensaverApplicationPath;
    if (alternateScreensaverID) {
        
        screensaverApplicationPath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:alternateScreensaverID];
        if (screensaverApplicationPath == nil) {
            NSLog(@"Cannot start alternate screensaver; could not find application with bundle identifier %@", alternateScreensaverID);
            return;
        }
        self.runningAlternateScreensaverBundleID = alternateScreensaverID;
        
    } else {
        
        screensaverApplicationPath = PATH_TO_SCREENSAVER_APPLICATION;
        
    }
    // Invoke the proper command line voodoo to start the screensaver.
    [NSTask launchedTaskWithLaunchPath:@"/usr/bin/open" arguments:@[ @"-a", screensaverApplicationPath ]];
}

-(void)stopScreensaver
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:ExitScreensaverBySimulatingKeystroke]) {
        
        NSArray *screensaverEngineResults = [NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.apple.ScreenSaver.Engine"];
        if (screensaverEngineResults.count > 0) {
            [NSTask launchedTaskWithLaunchPath:@"/usr/bin/osascript" arguments:@[ @"-e", @"tell application \"System Events\" to key code 123" ]];
        }
        
    } else if (self.runningAlternateScreensaverBundleID) {
        
        NSArray *results = [NSRunningApplication runningApplicationsWithBundleIdentifier:self.runningAlternateScreensaverBundleID];
        if (results.count > 0) {
            NSRunningApplication *alternateScreensaver = results[0];
            [alternateScreensaver terminate];
            self.runningAlternateScreensaverBundleID = nil;
        } else {
            NSLog(@"Alternate Screensaver Not Running.  Cannot terminate.");
        }
        
    } else {
        
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
}


@end
