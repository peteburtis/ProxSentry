//
//  ScreenDimController.m
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

#import "ScreenDimAction.h"
#import "BrightnessController.h"
#import "FaceDetectionController.h"

NSString * const ScreenDimmingDelayKey = @"ScreenDimmingDelay";

@interface ScreenDimAction ()

@property (nonatomic, strong) BrightnessController *brightnessController;
@property float predimmedBrightness;
@end

@implementation ScreenDimAction

-(id)init
{
    self = [super init];
    if (self) {
        /*
         Use -1 to indicate that the screen brightness level is set to whatever the user had it at, not dimmed by us.
         */
        self.predimmedBrightness = -1;
        
        /*
         Check the hidden preference "ScreenDimmingDelay".  If it exists, use it, otherwise use the default (0.85 seconds).
         Our superclass--DetectionActionController--will delay notification of faces exiting the camera field of view for faceExitTriggerDelay seconds.
         */
        NSTimeInterval screenDimmingDelayPreference = [[NSUserDefaults standardUserDefaults] doubleForKey:ScreenDimmingDelayKey];
        self.faceExitTriggerDelay = ( screenDimmingDelayPreference ? screenDimmingDelayPreference : SCREEN_DIMMING_DELAY_DEFAULT );
    }
    return self;
}

-(void)awakeFromNib
{
    /*
     Register for notifications here to avoid the spurious notifications sent during app initilization when the preference defaults are first configured.
     */
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(defaultsChangedNotification:)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];
}

-(void)defaultsChangedNotification:(NSNotification *)notification
{
    BOOL dimSettingIsOn = [[NSUserDefaults standardUserDefaults] boolForKey:@"DimScreen"];
    if (self.predimmedBrightness != -1 && ! dimSettingIsOn) {
        [self brightenScreen];
    } else if (self.predimmedBrightness == -1 && ! self.facesPresent && dimSettingIsOn) {
        [self dimScreen];
    }
}

#pragma mark - Accessors

-(BrightnessController *)brightnessController
{
    /*
     Create our brightness controller on demand when needed.
    */
    if (! _brightnessController)
        _brightnessController = [BrightnessController new];
    return _brightnessController;
}

-(BOOL)supported
{
    /*
     Use our brightness controller to determin if screen brightness setting is supported.
    */
    return self.brightnessController.brightnessSupported;
}

#pragma mark - Override Actions

-(void)faceDidEnterCameraFieldOfView
{
    armed = YES;
    if ( ! [[NSUserDefaults standardUserDefaults] boolForKey:@"DimScreen"]) return;
    [self brightenScreen];
}

-(void)faceDidExitCameraFieldOfView
{
    if ( ! [[NSUserDefaults standardUserDefaults] boolForKey:@"DimScreen"]) return;
    [self dimScreen];
}

-(void)faceDetectionDidDisable
{
    [self faceDidEnterCameraFieldOfView]; // Force screen to brighten again.
}

#pragma mark - Private Methods

-(void)brightenScreen
{
    /*
     Check that the sceen is dimmed by our request (self.predimmedBrightness != -1).
     
     Check that the brightness is still below our DIMMING_THRESHOLD. If it's above it, the user probably turned up the brightness by hand since we last dimmed the screen, so no don't mess with it.
     */
    
    if (self.predimmedBrightness != -1
        && self.brightnessController.brightness < DIMMING_THRESHOLD) {

        self.brightnessController.brightness = self.predimmedBrightness;
    }
    
    self.predimmedBrightness = -1;
}

-(void)dimScreen
{
    /*
     Check that the sceen isn't already dimmed by our request (self.predimmedBrightness == -1).
     
     Check that the user has brightness above a certain brightness level (DIMMING_THESHOLD). If it's below that level, no point in dimming the screen further.
     */
    
    if (self.predimmedBrightness == -1
        && self.brightnessController.brightness >= DIMMING_THRESHOLD
        && armed) {
        
        self.predimmedBrightness = self.brightnessController.brightness;
        [self.brightnessController backlightMaxDim];
    }
}

@end
