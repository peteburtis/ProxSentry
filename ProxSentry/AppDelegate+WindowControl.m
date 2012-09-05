//
//  AppDelegate+WindowControl.m
//  ProxSentry
//
//  Created by Peter on 9/3/12.
//  Copyright (c) 2012 Gray Goo Labs. All rights reserved.
//

#import "AppDelegate+WindowControl.h"
#import "FaceDetectionController.h"

NSString * const HUDWindowLastPosition = @"HUDWindowLastPosition";
NSString * const HUDWindowVisible = @"HUDWindowVisible";



@interface AppDelegate ()
// Private methods from AppDelegate prime that we need to call
@property (nonatomic) NSRect fullCameraViewFrame;
@property (nonatomic) BOOL returnHUDWindowToLastSize;
@property BOOL movingWindows;
@end



@implementation AppDelegate (WindowControl)

#pragma mark - User Actions

// Delegate method received from one of the two camera views
-(void)doubleClickViewDidDoubleClick:(NSView *)view
{
    [self flipWindows];
}

#pragma mark - Window Setup and Taredown

-(CALayer *)blackedOutLayer
{
    CALayer *standInLayer = [CALayer layer];
    standInLayer.backgroundColor = [[NSColor blackColor] CGColor];
    return standInLayer;
}

-(void)setupPreviewLayer
{
    /*
     Add the camera preview display to the main window.
     */
    self.cameraView.layer = self.faceDetectionController.videoPreviewLayer;
    self.cameraView.wantsLayer = YES;
}

-(void)removePreviewLayer
{
    self.cameraView.layer = [self blackedOutLayer];
}

#pragma mark - Window Control

-(void)animateHUDWindowZoomToContentFrame:(NSRect)frame completionHandler:(void (^)(void))complete
{
    NSUInteger windowExtraHeight = [[self.HUDWindow.contentView superview] frame].size.height - ((NSView *)self.HUDWindow.contentView).frame.size.height;
    
    NSRect newHUDWindowFrame = frame;
    newHUDWindowFrame.size.height += windowExtraHeight;
    [NSAnimationContext runAnimationGroup:
     ^(NSAnimationContext *(context)){
         [[self.HUDWindow animator] setFrame:newHUDWindowFrame display:YES animate:YES];
     }
                        completionHandler:complete];
}

-(void)flipWindows
{
    if ([self.window isVisible]) {
        [self showHUDWindow];
    } else {
        [self showMainWindow];
    }
}

-(void)showHUDWindow
{
    if ([self.window isVisible]) {
        self.fullCameraViewFrame = [self.window convertRectToScreen:self.cameraView.frame];
        NSRect startingHUDWindowFrame = self.fullCameraViewFrame;
        
        
        [self removePreviewLayer];
        [self.HUDWindow.contentView setLayer:self.faceDetectionController.videoPreviewLayer];
        [self.HUDWindow.contentView setWantsLayer:YES];
        
        [self.HUDWindow setFrame:startingHUDWindowFrame display:NO];
        [self.HUDWindow setContentSize:startingHUDWindowFrame.size];
        [self.HUDWindow makeKeyAndOrderFront:self];
        
        [self.window orderOut:self];
        
        NSRect newHUDWindowFrame;
        if (self.returnHUDWindowToLastSize) {
            newHUDWindowFrame = NSRectFromString([[NSUserDefaults standardUserDefaults] objectForKey:HUDWindowLastPosition]);
        } else {
            NSSize finalSize = HUD_WINDOW_FINAL_SIZE;
            newHUDWindowFrame.origin = self.window.frame.origin;
            newHUDWindowFrame.size = finalSize;
            // Center the HUD window under the old
            newHUDWindowFrame.origin.x += startingHUDWindowFrame.size.width / 2 - finalSize.width / 2;
            newHUDWindowFrame.origin.y += startingHUDWindowFrame.size.height / 2 - finalSize.height / 2;
        }
        
        [self animateHUDWindowZoomToContentFrame:newHUDWindowFrame completionHandler:^{
            [self saveHUDPreferences];
        }];
    } else {
        [self.HUDWindow makeKeyAndOrderFront:self];
    }
}

-(void)showMainWindow
{
    if ([self.HUDWindow isVisible]) {
        self.movingWindows = YES;
        self.returnHUDWindowToLastSize = YES;
        
        NSRect currentHUDWindowFrame = self.HUDWindow.frame;
        NSRect newHUDWindowFrame = self.fullCameraViewFrame; // fullCameraViewFrame for size; origin is off for now
        NSRect newMainWindowFrame = self.window.frame; // for size, origin is off until...
        
        // Get the final origin of the main window by centering with HUDWindow
        newMainWindowFrame.origin.x = currentHUDWindowFrame.origin.x + (currentHUDWindowFrame.size.width / 2 - newHUDWindowFrame.size.width / 2);
        newMainWindowFrame.origin.y = currentHUDWindowFrame.origin.y + (currentHUDWindowFrame.size.height / 2 - newHUDWindowFrame.size.height / 2);
        
        
        // If the final window will be off the screen, fix it
        NSRect screenBounds = self.HUDWindow.screen.visibleFrame;
        NSInteger maxX = screenBounds.size.width - newMainWindowFrame.size.width - 10;
        NSInteger maxY = screenBounds.size.width - newMainWindowFrame.size.width - 10;
        if (newMainWindowFrame.origin.x > maxX)
            newMainWindowFrame.origin.x = maxX;
        if (newMainWindowFrame.origin.y > maxY)
            newMainWindowFrame.origin.y = maxY;
        
        if (newMainWindowFrame.origin.x < screenBounds.origin.x)
            newMainWindowFrame.origin.x = screenBounds.origin.x + 10;
        if (newMainWindowFrame.origin.y < screenBounds.origin.y)
            newMainWindowFrame.origin.y = screenBounds.origin.y + 10;
        
        
        // Last but not least, the new HUD window origin has to match main window origin
        newHUDWindowFrame.origin = newMainWindowFrame.origin;
        
        [self.window setFrame:newMainWindowFrame display:NO animate:NO];
        [self animateHUDWindowZoomToContentFrame:newHUDWindowFrame completionHandler:^{
            [self.window orderBack:self];
            
            [self.HUDWindow.contentView setLayer:[self blackedOutLayer]];
            [self.HUDWindow orderOut:self];
            
            [self setupPreviewLayer];
            
            [self saveHUDPreferences];
            self.movingWindows = NO;
            
            [self.window.contentView setNeedsDisplay:YES];
        }];
    } else {
        [NSApp activateIgnoringOtherApps:YES];
        [self setupPreviewLayer];
        [self.window makeKeyAndOrderFront:self];
    }
}

#pragma mark - Preferences Stuff

-(void)saveHUDPreferences
{
    /*
     Save the height just the content, not the whole window, because resize method is designed to take it that way.
     */
    NSRect rectToSave = self.HUDWindow.frame;
    rectToSave.size = [self.HUDWindow.contentView frame].size; // Save the height of the whole window
    BOOL HUDIsVisible = [self.HUDWindow isVisible];
    if (HUDIsVisible)
        [[NSUserDefaults standardUserDefaults] setValue:NSStringFromRect(rectToSave) forKey:HUDWindowLastPosition];
    
    [[NSUserDefaults standardUserDefaults] setBool:HUDIsVisible forKey:HUDWindowVisible];
}

-(void)restoreHUD
{
    /*
     Only to be called durinig app startup; do the absolute minimum to get the HUD on screen, and have switchToMainWindow work when called
     */
    self.fullCameraViewFrame = self.cameraView.frame;

    [self.HUDWindow.contentView setLayer:[self.faceDetectionController videoPreviewLayer]];
    [self.HUDWindow.contentView setWantsLayer:YES];
    [self.HUDWindow setFrame:NSRectFromString([[NSUserDefaults standardUserDefaults] objectForKey:HUDWindowLastPosition])
                     display:NO];
    
    [self.HUDWindow makeKeyAndOrderFront:self];
}

#pragma mark - Window Delegate Stuff

- (BOOL)windowShouldZoom:(NSWindow *)window toFrame:(NSRect)newFrame
{
    [self flipWindows];
    return NO;
}

-(void)windowWillClose:(NSNotification *)notification
{
    self.returnHUDWindowToLastSize = NO;
    if (notification.object == self.HUDWindow) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:HUDWindowVisible];
    }
}

-(void)windowDidMove:(NSNotification *)notification
{
    if (self.movingWindows) return;
    
    if (notification.object == self.window) {
        self.returnHUDWindowToLastSize = NO;
    } else {
        [self saveHUDPreferences];
    }
}

@end
