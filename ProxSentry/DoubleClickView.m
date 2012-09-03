//
//  DoubleClickView.m
//  ProxSentry
//
//  Created by Peter on 9/3/12.
//  Copyright (c) 2012 Gray Goo Labs. All rights reserved.
//

#import "DoubleClickView.h"

@interface NSObject ()
-(void)doubleClickViewDidDoubleClick:(id)doubleClickView;
@end

@implementation DoubleClickView

-(void)mouseUp:(NSEvent *)theEvent
{
    if ([theEvent clickCount] == 2) {
        [self.delegate doubleClickViewDidDoubleClick:self];
    } else {
        [super mouseUp:theEvent];
    }
}

@end