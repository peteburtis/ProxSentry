//
//  MenuItemController.h
//  ProxSentry
//
//  Created by Peter on 8/28/12.
//  Copyright (c) 2012 Gray Goo Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

#define STATUS_ITEM_LENGTH 25
#define MENU_FLASH_INTERVAL 0.75

@class FaceDetectionController;

@interface StatusMenuController : NSObject

@property (nonatomic, weak) IBOutlet NSMenu *menu;
@property (nonatomic, weak) IBOutlet FaceDetectionController *faceDetectionController;
@property (nonatomic) BOOL menuItemEnabled;


@end
