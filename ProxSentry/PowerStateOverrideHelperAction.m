//
//  PowerStateOverrideHelperAction.m
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

#import "PowerStateOverrideHelperAction.h"
extern NSString * const FaceDetectionControllerWillNotifyFaceDidEnter;

@implementation PowerStateOverrideHelperAction

-(id)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(preFaceEntryNotification:)
                                                     name:FaceDetectionControllerWillNotifyFaceDidEnter
                                                   object:nil];
    }
    return self;
}

-(void)preFaceEntryNotification:(NSNotification *)notification
{
    if (_attemptSystemWakeUpOnFaceDetection) {
        NSLog(@"Attempting to wake system");
        IOPMAssertionID assertionID;
        IOPMAssertionDeclareUserActivity(CFSTR("ProxSentry Wake Up Screen Upon Face Detection"),
                                         kIOPMUserActiveLocal,
                                         &assertionID);
        
        
        self.attemptSystemWakeUpOnFaceDetection = NO;
    }
}

@end
