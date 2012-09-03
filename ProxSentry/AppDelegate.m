//
//  AppDelegate.m
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
 Code to detect display sleep via IODisplayWrangler inspired by Adam Davis' answer @ http://stackoverflow.com/questions/4929731/check-if-display-is-at-sleep-or-receive-sleep-notifications
 */

#import "AppDelegate.h"
#import "FaceDetectionController.h"
#import "BatteryPowerMonitor.h"
#import "PowerStateOverrideHelperAction.h"

#import "SleepSuppressionAction.h"
#import "ScreenDimAction.h"
#import "ScreenLockAction.h"

#import "BatteryPowerMonitor.h"
#import "StatusMenuController.h"

NSString * const AlwaysDisableCameraOnDisplaySleep = @"AlwaysDisableCameraOnDisplaySleep";

@implementation AppDelegate

-(id)init
{
    self = [super init];
    if (self) {
        [[NSUserDefaults standardUserDefaults] registerDefaults:@{
         
         SuppressSleep :             @(YES),
         DimScreen :                 @(YES),
         LockScreen :                @(NO),
         LockMode :                  @(1),
         LockDuration :              @(300),
         UnlockScreen :              @(YES),
         BatteryAutoDisables :       @(NO),
         MenuItemEnabled :           @(YES)
         
         
         }];
    }
    return self;
}

#pragma mark - AppDelegate overrides

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self setupPreviewLayer];
    [self registerForSleepNotifications];
    [self setupDisplayPowerCallback];
    
    // Activate the camera and face detection if appropriate
    if ([self batteryConditionsAllowActivation]) {
        self.faceDetectionController.enabled = YES;
    }
    
    // Setup and show the window
    [self.window setLevel:NSStatusWindowLevel];
    if ( ! [NSApp isHidden]) {
        [self showMainWindow:self];
    }
}

-(BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)hasVisibleWindows
{
    /*
     Show the control panel if the user double clicks our icon in the finder while we're already running.
     */
    [self showMainWindow:self];
    return NO;
}

#pragma mark - IBActions

-(IBAction)showAboutPanel:(id)sender
{
    /*
     Because we change the window level of the main window, the standard about panel shows up behind it
     
     Changing the window level of the standard about panel appears non-trivial, and I am very, very tired,
     so I'll just close the main window when the user clicks on "About", for now.
    */
    [NSApp orderFrontStandardAboutPanel:sender];
    [self.window orderOut:sender];
}

-(IBAction)showMainWindow:(id)sender
{
    /*
     Seem to have to explicitly activate the app when dealing with a UIElement application.
    */
    [NSApp activateIgnoringOtherApps:YES];
    [self.window makeKeyAndOrderFront:self];
}

#pragma mark - Private Methods

-(void)setupPreviewLayer
{
    /*
     Add the camera preview display to the main window.
     */
    AVCaptureVideoPreviewLayer *previewLayer = [self.faceDetectionController videoPreviewLayer];
    self.cameraView.layer = previewLayer;
    [self.cameraView setWantsLayer:YES];
}

-(void)removePreviewLayer
{
    CALayer *standInLayer = [CALayer layer];
    standInLayer.backgroundColor = [[NSColor blackColor] CGColor];
    self.cameraView.layer = standInLayer;
}

-(BOOL)batteryConditionsAllowActivation
{
    return (self.batteryPowerMonitor.onBatteryPower == NO || [[NSUserDefaults standardUserDefaults] boolForKey:BatteryAutoDisables] == NO);
}

#pragma mark - Power Management Stuff

#pragma mark System Sleep

-(void)registerForSleepNotifications
{
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
                                                           selector:@selector(sleepNotification:)
                                                               name:NSWorkspaceWillSleepNotification
                                                             object:nil];
    
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
                                                           selector:@selector(wakeNotification:)
                                                               name:NSWorkspaceDidWakeNotification
                                                             object:NULL];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(screenLockActionWillForceSleepNotification:)
                                                 name:ScreenLockActionWillForceSleepNotification
                                               object:nil];
}

-(void)screenLockActionWillForceSleepNotification:(NSNotification *)notification
{
    /*
     What we have here is a workaround:
     OS X (or at least the pre-release 10.8.2 that I'm working on) seems none too happy when it tries to sleep while the camera is active. It blacks out the screen, but keeps the backlight on and the cursor visible for 30 seconds after the sleep command is issued.  Disabling the camera after we get notified that the system will sleep doesn't help.  So, at least when we know that we're the ones issuing the sleep command, we disable the camera before we issue the command.
     */
    needsRestartAfterSystemSleep = self.faceDetectionController.enabled;
    self.faceDetectionController.activationDisabledForSystemSleep = YES;
}

/*
 The webcam does not seem to be available immediately following a sleep, so we disable everything before entering a sleep, and reenable everything only after we get kIOMessageSystemHasPoweredOn, which comes 5-15 seconds after everything appears to be up and running to the user.
*/

-(void)sleepNotification:(NSNotification *)notification
{
    /*
     If the whole system goes to sleep while the display is already asleep, we no longer want to wake the camera when the display wakes up.  Rather, we go through the more through waking of the camera done when the whole system wakes up.
     */
    
    if ( ! self.faceDetectionController.activationDisabledForSystemSleep) {
        
        needsRestartAfterSystemSleep = ( self.faceDetectionController.enabled || needsRestartAfterDisplaySleep );
        needsRestartAfterDisplaySleep = NO;
        self.faceDetectionController.activationDisabledForSystemSleep = YES;
        
    }
    
    [self removePreviewLayer];
}

-(void)wakeNotification:(NSNotification *)notification
{
    self.faceDetectionController.activationDisabledForSystemSleep = NO;
    if (needsRestartAfterSystemSleep && [self batteryConditionsAllowActivation]) {
        self.faceDetectionController.enabled = YES;
    }
    [self setupPreviewLayer];
}

#pragma mark Display Sleep

-(void)setupDisplayPowerCallback
{
    /*
     This sets up a callback that informs us when the display is dimmed by the system, goes to sleep or wakes up. Unlike full system sleep, we're still running while just the display is asleep.
     */
    io_object_t notification = 0;
    
    io_service_t displayWrangler = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceNameMatching("IODisplayWrangler"));
    if ( ! displayWrangler) return;
    
    IONotificationPortRef notificationPort = IONotificationPortCreate(kIOMasterPortDefault);
    if ( ! notificationPort) return;
    
    IOServiceAddInterestNotification(notificationPort,
                                     displayWrangler,
                                     kIOGeneralInterest,
                                     DisplayPowerChangeCallback,
                                     (__bridge void *)self,
                                     &notification);
    if (notification == 0) return;
                                                  
    CFRunLoopAddSource(CFRunLoopGetCurrent(), IONotificationPortGetRunLoopSource(notificationPort), kCFRunLoopDefaultMode);
    IOObjectRelease(displayWrangler);
}

-(void)displayWillBeDimmedBySystem
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:DimScreen]) {
        /*
         If we dim the display, and then the system dims the display, the user doesn't see any change, but when we attempt to wake the display, the system dim wins and nothing happens. We can defeat this by faking user activity when we detect a face, which wakes the display and deactivates the system's dim.
         */
        self.powerHelper.attemptSystemWakeUpOnFaceDetection = YES;
    }
    NSLog(@"System Did Dim Screen");
}

-(void)displayWillSleep
{
    /*
     Two basic strategies when the system sleeps the display:
     
     If we aren't set to kill the screensaver when user returns, then we just shutdown the camera; full system sleep doesn't seem to work when the camera is on, and we want to respect the users full sleep setting.
     
     If we are set to kill the screensaver, then we leave the camera on, sleep be damned, and attempt to wake the system when the user returns.
     */
    
    BOOL universalDisplaySleepPref = [[NSUserDefaults standardUserDefaults] boolForKey:AlwaysDisableCameraOnDisplaySleep];
    
    NSUInteger lockMode = [[NSUserDefaults standardUserDefaults] integerForKey:LockMode];
    BOOL unlockScreenPref = [[NSUserDefaults standardUserDefaults] integerForKey:UnlockScreen];
    if ( universalDisplaySleepPref || lockMode != 0 || ! unlockScreenPref ) {
        
        needsRestartAfterDisplaySleep = self.faceDetectionController.enabled;
        self.faceDetectionController.enabled = NO;
        
    } else {
        
        self.powerHelper.attemptSystemWakeUpOnFaceDetection = YES;
        
    }
    NSLog(@"System Did Sleep Screen");
}

-(void)displayDidWake
{
    if (needsRestartAfterDisplaySleep) {
        self.faceDetectionController.enabled = YES;
        needsRestartAfterDisplaySleep = NO;
    }
    
    self.powerHelper.attemptSystemWakeUpOnFaceDetection = NO;
    NSLog(@"System Did Wake Screen");
}

void DisplayPowerChangeCallback(void *refcon, io_service_t service, natural_t messageType, void *messageArgument)
{
    /*
     This callback gets many messages, not just the two we look for below. 
     
     The system actually sends kIOMessageDeviceWillPowerOff twice; first when it dims the display to warn the user that sleep is imminent, and again when it actually sleeps the display.  We figure out which one is which, and call methods on the AppDelegate appropriately.
     */
    static BOOL displayIsDimmedBySystem = NO;
    AppDelegate *appDelegate = (__bridge AppDelegate *)refcon;
    
    if (messageType == kIOMessageDeviceWillPowerOff) {
        if (displayIsDimmedBySystem) {
            [appDelegate displayWillSleep];
            
        } else {
            [appDelegate displayWillBeDimmedBySystem];
            displayIsDimmedBySystem = YES;
            
        }
    } else if (messageType == kIOMessageDeviceHasPoweredOn) {
        [appDelegate displayDidWake];
        displayIsDimmedBySystem = NO;
        
    }
}

@end
