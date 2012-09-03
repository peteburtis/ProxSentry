//
//  AppDelegate+WindowControl.m
//  ProxSentry
//
//  Created by Peter on 9/3/12.
//  Copyright (c) 2012 Gray Goo Labs. All rights reserved.
//

#import "AppDelegate+WindowControl.h"

@interface AppDelegate ()
// Private methods from AppDelegate prime that we need to call
-(void)setupPreviewLayer;
-(void)removePreviewLayer;
-(CALayer *)blackedOutLayer;
@property (nonatomic) NSRect fullCameraViewFrame;
@end

@implementation AppDelegate (WindowControl)

#pragma mark - User Actions

// Delegate method received from one of the two camera views
-(void)doubleClickViewDidDoubleClick:(NSView *)view
{
    [self flipWindows];
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
        [self switchToHUDWindow];
    } else {
        [self switchToMainWindow];
    }
}

-(void)switchToHUDWindow
{
    NSSize finalSize = HUD_WINDOW_FINAL_SIZE;
    self.fullCameraViewFrame = [self.window convertRectToScreen:self.cameraView.frame];
    NSRect startingHUDWindowFrame = self.fullCameraViewFrame;
    
    
    CALayer *videoLayer = self.cameraView.layer;
    [self removePreviewLayer];
    [self.HUDWindow.contentView setLayer:videoLayer];
    [self.HUDWindow.contentView setWantsLayer:YES];
    
    [self.HUDWindow setFrame:startingHUDWindowFrame display:NO];
    [self.HUDWindow setContentSize:startingHUDWindowFrame.size];
    [self.HUDWindow makeKeyAndOrderFront:self];
    
    [self.window orderOut:self];
    
    NSRect newHUDWindowFrame;
    newHUDWindowFrame.origin = self.window.frame.origin;
    newHUDWindowFrame.size = finalSize;
    // Center the HUD window
    newHUDWindowFrame.origin.x += startingHUDWindowFrame.size.width / 2 - finalSize.width / 2;
    newHUDWindowFrame.origin.y += startingHUDWindowFrame.size.height / 2 - finalSize.height / 2;
    
    [self animateHUDWindowZoomToContentFrame:newHUDWindowFrame completionHandler:NULL];
}

-(void)switchToMainWindow
{
    // This *almost* works; needs to account for the dock...
    
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
        [self setupPreviewLayer];
        
        [self.HUDWindow.contentView setLayer:[self blackedOutLayer]];
        [self.HUDWindow orderOut:self];
    }];
}

#pragma mark - Window Delegate Stuff

- (BOOL)windowShouldZoom:(NSWindow *)window toFrame:(NSRect)newFrame
{
    [self flipWindows];
    return NO;
}

@end
