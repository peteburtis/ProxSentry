//
//  StartupItemController.m
//  ProxSentry
//
//  Created by Peter on 8/29/12.
//  Copyright (c) 2012 Gray Goo Labs. All rights reserved.
//

#import "LoginItemController.h"

@implementation LoginItemController

+(BOOL)automaticallyNotifiesObserversForKey:(NSString *)theKey {
    return NO;
}

-(id)init
{
    self = [super init];
    if (self) {
        loginItemStatus = -1;
        LSSharedFileListRef listRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
        LSSharedFileListAddObserver(listRef,
                                    CFRunLoopGetMain(),
                                    kCFRunLoopCommonModes,
                                    LoginStatusChangeCallback,
                                    (__bridge void *)self);
    }
    return self;
}


-(void)loginStatusChange
{
    if (loginItemStatus == -1) {
        // No one is watching us yet, so it doesn't matter that the login status potentially changed
        return;
    }    
    LSSharedFileListItemRef item = [self retainedMainBundleSharedFileListItemRef];
    BOOL newState;
    if (item) {
        newState = YES;
        CFRelease(item);
    } else {
        newState = NO;
    }
    
    if (newState != loginItemStatus) {
        
        [self willChangeValueForKey:@"loginItemEnabled"];
        loginItemStatus = newState;
        [self didChangeValueForKey:@"loginItemEnabled"];
        
    }
}

void LoginStatusChangeCallback(LSSharedFileListRef list, void * context)
{
    LoginItemController *loginItemController = (__bridge LoginItemController*)context;
    [loginItemController loginStatusChange];
}


-(LSSharedFileListItemRef)retainedMainBundleSharedFileListItemRef
{
    /*
     Search through the system's list of login items to find our own.
     
     This method returns a LSSharedFileListItemRef with a retain count of 1, which I realize is a bit weird. It's nessecary because once the currentItems array is freed, item is potentially retain count 0.
     
     Too bad there's no CFAutorelease...
    */
    
    LSSharedFileListRef listRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    CFArrayRef currentItems = LSSharedFileListCopySnapshot(listRef, NULL);
    CFIndex itemCount = CFArrayGetCount(currentItems);
    NSURL *appURL = [[NSBundle mainBundle] bundleURL];
    
    LSSharedFileListItemRef result = NULL;
    
    for (int i = 0; i < itemCount; ++i) {
        LSSharedFileListItemRef item = (LSSharedFileListItemRef)CFArrayGetValueAtIndex(currentItems, i);
        CFURLRef itemURLRef = nil;
        LSSharedFileListItemResolve(item,
                                    0,
                                    &itemURLRef,
                                    NULL);
        
        NSURL *itemURL = CFBridgingRelease(itemURLRef);
        
        if ([appURL isEqual:itemURL]) {
            result = (LSSharedFileListItemRef)CFRetain(item);
            break;
        }
    }
    
    CFRelease(currentItems);
    CFRelease(listRef);
    
    return result;
}

-(BOOL)loginItemEnabled
{
    /*
     loginItemStatus will be:
     -1 if unknown
     0 if off
     1 if on
     
     If we already know the state of our loginItem, use that.  Otherwise, query the system to find out.
    */
    
    if (loginItemStatus > -1)
        return loginItemStatus;
    
    LSSharedFileListItemRef item = [self retainedMainBundleSharedFileListItemRef];
    if (item) {
        loginItemStatus = 1;
        CFRelease(item);
        return YES;
    } else {
        loginItemStatus = 0;
        return NO;
    }
}

-(void)setLoginItemEnabled:(BOOL)loginItemEnabled
{
    /*
     Insert ourself into, or remove ourself from the system login items list.
     */
    
    LSSharedFileListRef listRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    
    if (loginItemEnabled) {
        
        NSDictionary *properties = @{(__bridge NSString *)kLSSharedFileListLoginItemHidden: (id)kCFBooleanTrue};
        LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(listRef,
                                                                     kLSSharedFileListItemLast,
                                                                     NULL,
                                                                     NULL,
                                                                     (__bridge CFURLRef)[[NSBundle mainBundle] bundleURL],
                                                                     (__bridge CFDictionaryRef)properties,
                                                                     NULL);
        
        CFRelease(item);
        
    } else {
        
        LSSharedFileListItemRef ourItem = [self retainedMainBundleSharedFileListItemRef];
        if (ourItem) {
            LSSharedFileListItemRemove(listRef, ourItem);
            CFRelease(ourItem);
        }
        
    }
    CFRelease(listRef);
}

@end
