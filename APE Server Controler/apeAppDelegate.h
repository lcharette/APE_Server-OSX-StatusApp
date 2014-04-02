//
//  apeAppDelegate.h
//  APE Server Controler
//
//  Created by Louis Charette on 2014-04-01.
//  Copyright (c) 2014 APE-Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface apeAppDelegate : NSObject <NSApplicationDelegate>

@property (strong, nonatomic) NSStatusItem *statusItem;
@property (nonatomic, strong) __block NSTask *APEtask;

@property (weak) IBOutlet NSMenu *StatusMenu;
@property (weak) IBOutlet NSMenuItem *MenuItemServerState;
@property (weak) IBOutlet NSMenuItem *MenuItemStartCmd;
@property (weak) IBOutlet NSMenuItem *MenuItemStopCmd;

@end
