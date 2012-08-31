//
//  MenuItemController.m
//  ProxSentry
//
//  Created by Peter on 8/28/12.
//  Copyright (c) 2012 Gray Goo Labs. All rights reserved.
//

#import "StatusMenuController.h"
#import "FaceDetectionController.h"

@interface StatusMenuController ()
@property (strong) NSStatusItem *statusItem;
@property (strong) NSTimer *menuFlashTimer;
@end

@implementation StatusMenuController

-(id)init
{
    self = [super init];
    if (self) {        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(faceStateChangedNotification:)
                                                     name:FaceDidEnterCameraFieldOfViewNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(faceStateChangedNotification:)
                                                     name:FaceDidExitCameraFieldOfViewNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(faceStateChangedNotification:)
                                                     name:FaceDetectionEnabledStateDidChangeNotification
                                                   object:nil];
    }
    return self;
}

-(void)awakeFromNib
{
    self.menuItemEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"MenuItemEnabled"];
}

-(void)setMenuItemEnabled:(BOOL)menuItemEnabled
{
    if (_menuItemEnabled != menuItemEnabled) {
        _menuItemEnabled = menuItemEnabled;
        
        if (_menuItemEnabled) {
            self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:STATUS_ITEM_LENGTH];
            self.statusItem.highlightMode = YES;
            self.statusItem.menu = self.menu;
            [self updateMenuItemIcon];
            
        } else {
            [[NSStatusBar systemStatusBar] removeStatusItem:self.statusItem];
            self.statusItem = nil;
            
        }
        
        [[NSUserDefaults standardUserDefaults] setBool:_menuItemEnabled forKey:@"MenuItemEnabled"];
    }
}

#pragma mark - Image Control

-(void)startFlashingMenu
{
    if (self.menuFlashTimer) return;
    
    self.menuFlashTimer = [NSTimer scheduledTimerWithTimeInterval:MENU_FLASH_INTERVAL
                                                           target:self
                                                         selector:@selector(menuFlashTimerFired:)
                                                         userInfo:nil
                                                          repeats:YES];
}

-(void)stopFlashingMenu
{
    [self.menuFlashTimer invalidate];
    self.menuFlashTimer = nil;
}

-(void)menuFlashTimerFired:(NSTimer *)timer
{
    static BOOL flashState = NO;
    NSImage *image;
    if (flashState) {
        image = [self offImage];
    } else {
        image = [self disabledImage];
    }
    flashState = ! flashState;
    [self.statusItem setImage:image];
}

-(void)updateMenuItemIcon
{
    if (self.faceDetectionController.activationDisabledForSystemSleep) {
        [self startFlashingMenu];
    } else {
        [self stopFlashingMenu];
        
        NSImage *image;
        if (self.faceDetectionController.facesPresent && self.faceDetectionController.enabled) {
            image = [self onImage];
        } else if (self.faceDetectionController.enabled) {
            image = [self offImage];
        } else {
            image = [self disabledImage];
        }
        [self.statusItem setImage:image];
    }
}

-(void)faceStateChangedNotification:(NSNotification *)notification
{
    [self updateMenuItemIcon];
}

#pragma mark - Image Loaders

-(NSImage *)onImage
{
    return [NSImage imageNamed:@"MenuIconOn"];
}

-(NSImage *)offImage
{
    return [NSImage imageNamed:@"MenuIconOff"];
}

-(NSImage *)disabledImage
{
    return [NSImage imageNamed:@"MenuIconDisabled"];
}

@end
