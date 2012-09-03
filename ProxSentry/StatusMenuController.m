//
//  MenuItemController.m
//  ProxSentry
//
//  Created by Peter on 8/28/12.
//  Copyright (c) 2012 Gray Goo Labs. All rights reserved.
//

#import "StatusMenuController.h"
#import "FaceDetectionController.h"

NSString * const MenuItemEnabled = @"MenuItemEnabled";

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
    self.menuItemEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:MenuItemEnabled];
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
        
        [[NSUserDefaults standardUserDefaults] setBool:_menuItemEnabled forKey:MenuItemEnabled];
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
    NSImage *altImage;
    if (flashState) {
        image = [self offImage];
        altImage = [self offImageAlt];
    } else {
        image = [self disabledImage];
        altImage = [self disabledImageAlt];
    }
    flashState = ! flashState;
    [self.statusItem setImage:image];
    [self.statusItem setAlternateImage:altImage];
}

-(void)updateMenuItemIcon
{
    if (self.faceDetectionController.activationDisabledForSystemSleep) {
        [self startFlashingMenu];
    } else {
        [self stopFlashingMenu];
        
        NSImage *image;
        NSImage *altImage;
        if (self.faceDetectionController.facesPresent && self.faceDetectionController.enabled) {
            image = [self onImage];
            altImage = [self onImageAlt];
        } else if (self.faceDetectionController.enabled) {
            image = [self offImage];
            altImage = [self offImageAlt];
        } else {
            image = [self disabledImage];
            altImage = [self disabledImageAlt];
        }
        [self.statusItem setImage:image];
        [self.statusItem setAlternateImage:altImage];
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
-(NSImage *)onImageAlt
{
    return [NSImage imageNamed:@"MenuIconOnAlt"];
}

-(NSImage *)offImage
{
    return [NSImage imageNamed:@"MenuIconOff"];
}
-(NSImage *)offImageAlt
{
    return [NSImage imageNamed:@"MenuIconOffAlt"];
}

-(NSImage *)disabledImage
{
    return [NSImage imageNamed:@"MenuIconDisabled"];
}
-(NSImage *)disabledImageAlt
{
    return [NSImage imageNamed:@"MenuIconDisabledAlt"];
}

@end
