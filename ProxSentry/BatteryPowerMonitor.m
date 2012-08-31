//
//  BatteryPowerMonitor.m
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

#import "BatteryPowerMonitor.h"
#import "FaceDetectionController.h"

@implementation BatteryPowerMonitor

-(id)init
{
    self = [super init];
    if (self) {
        CFRunLoopSourceRef runLoopSource = IOPSNotificationCreateRunLoopSource(PowerCallback, (__bridge void *)self);
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, kCFRunLoopCommonModes);
        [self updatePowerConfiguration];
    }
    return self;
}

-(void)configureForRunningOnAC
{
    if (_onBatteryPower == NO) return;
    
    self.faceDetectionController.enabled = YES;
    self.onBatteryPower = NO;
}

-(void)configureForRunningOnBattery
{
    if (_onBatteryPower == YES) return;
    
    self.faceDetectionController.enabled = NO;
    self.onBatteryPower = YES;
}

-(void)updatePowerConfiguration
{
    if ( ! [[NSUserDefaults standardUserDefaults] boolForKey:@"BatteryAutoDisables"]) return;
    
    CFTimeInterval timeRemaining = IOPSGetTimeRemainingEstimate();
    if (timeRemaining == kIOPSTimeRemainingUnlimited)
        [self configureForRunningOnAC];
    else
        [self configureForRunningOnBattery];
}

void PowerCallback(void *context) {
    BatteryPowerMonitor *batteryPowerMonitor = (__bridge BatteryPowerMonitor *)context;
    [batteryPowerMonitor updatePowerConfiguration];
}

@end

