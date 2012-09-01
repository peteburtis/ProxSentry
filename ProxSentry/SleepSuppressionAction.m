//
//  SleepSuppressionController.m
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

#import "SleepSuppressionAction.h"

NSString * const SuppressSleep = @"SuppressSleep";
NSString * const SleepSuppressionDeactivationDelayKey = @"SleepSuppressionDeactivationDelay";

@interface SleepSuppressionAction ()
@property (assign) IOPMAssertionID powerAssertion;
@end

@implementation SleepSuppressionAction

-(id)init
{
    self = [super init];
    if (self) {        
        /*
         Check the hidden preference "SleepSuppressionDeactivationDelay".  If it exists, use it, otherwise use the default (30 seconds). Our superclass--DetectionActionController--will delay notification of faces exiting the camera field of view for faceExitTriggerDelay seconds.
         */
        NSTimeInterval sleepSuppressionDelayPreference = [[NSUserDefaults standardUserDefaults] doubleForKey:SleepSuppressionDeactivationDelayKey];
        self.faceExitTriggerDelay = ( sleepSuppressionDelayPreference ? sleepSuppressionDelayPreference : SLEEP_SUPPRESSION_DEACTIVATION_DELAY_DEFAULT );
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

-(void)dealloc
{
    self.sleepSuppressed = NO;
}

-(void)faceDidEnterCameraFieldOfView
{
    if ( ! [[NSUserDefaults standardUserDefaults] boolForKey:SuppressSleep]) return;
    self.sleepSuppressed = YES;
}

-(void)faceDidExitCameraFieldOfView
{
    self.sleepSuppressed = NO;
}

-(void)faceDetectionDidDisable
{
    self.sleepSuppressed = NO;
}

-(void)defaultsChangedNotification:(NSNotification *)notification
{
    self.sleepSuppressed = [[NSUserDefaults standardUserDefaults] boolForKey:SuppressSleep] && self.facesPresent;
}

-(void)setSleepSuppressed:(BOOL)sleepSuppressed
{
    if (_sleepSuppressed != sleepSuppressed) {
        _sleepSuppressed = sleepSuppressed;
        if (sleepSuppressed) {
            /*
             Create a power assertion to keep the display awake.
             */
            IOPMAssertionCreateWithName(kIOPMAssertionTypePreventUserIdleDisplaySleep,
                                        kIOPMAssertionLevelOn,
                                        CFSTR("ProxSentry User Present"),
                                        &_powerAssertion);
        } else {
            /*
             Destroy the power assertion.
             */
            IOPMAssertionRelease(_powerAssertion);
        }
    }
}


@end
