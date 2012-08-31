//
//  BrightnessController.m
//  Razorgirl
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

#import <IOKit/graphics/IOGraphicsLib.h>
#import "BrightnessController.h"

#define MAX_DISPLAYS 32

@implementation BrightnessController

@dynamic brightness;

-(float)brightness
{
    CGDirectDisplayID displays[MAX_DISPLAYS];
    CGDisplayCount displayCount;
    CGDisplayErr displayError;
    IOReturn IOErr;
    
    displayError = CGGetActiveDisplayList(MAX_DISPLAYS, displays, &displayCount);
    
    if (displayError != CGDisplayNoErr) {
        return -2;
    }
    
    for (int i = 0; i < displayCount; ++i) {
        CGDirectDisplayID display = displays[i];
        io_service_t displayServicePort = CGDisplayIOServicePort(display);
                
        float brightness;
        IOErr = IODisplayGetFloatParameter(displayServicePort, kNilOptions, CFSTR(kIODisplayBrightnessKey), &brightness);
        if (IOErr == kIOReturnSuccess) {
            return brightness;
        }
    }
    
    return -1;
}

-(void)setBrightness:(float)brightness
{
    if (brightness > 1.0) brightness = 1.0;
    if (brightness < 0.0) brightness = 0.0;
    
    CGDirectDisplayID displays[MAX_DISPLAYS];
    CGDisplayCount displayCount;
    CGDisplayErr displayError;
    
    displayError = CGGetActiveDisplayList(MAX_DISPLAYS, displays, &displayCount);
    
    if (displayError != CGDisplayNoErr) {
        return;
    }
    
    for (int i = 0; i < displayCount; ++i) {
        CGDirectDisplayID display = displays[i];
        io_service_t displayService = CGDisplayIOServicePort(display);
        
        
        IODisplaySetFloatParameter(displayService, kNilOptions, CFSTR(kIODisplayBrightnessKey), brightness);
    }
}

-(BOOL)brightnessSupported
{
    return (self.brightness >= 0);
}

-(void)backlightFullOn
{
    self.brightness = 1.0;
}
-(void)backlightOff
{
    self.brightness = 0.0;
}
-(void)backlightMaxDim
{
    self.brightness = 0.05;
}

@end
