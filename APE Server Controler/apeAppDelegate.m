//
//  apeAppDelegate.m
//  APE Server Controler
//
//  Created by Louis Charette on 2014-04-01.
//  Copyright (c) 2014 APE-Project. All rights reserved.
//

#import "apeAppDelegate.h"

@implementation apeAppDelegate {
    BOOL ApeIsInstaled;
}
@synthesize statusItem, StatusMenu;
@synthesize MenuItemServerState, MenuItemStartCmd, MenuItemStopCmd;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{    
    //Create the status item
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];

    //Set the image
    NSImage *menuIcon = [NSImage imageNamed:@"Status Bar Icon"];
    [[self statusItem] setImage:menuIcon];
    
    //Add the menu to the status item and set other stuff
    [self.statusItem setMenu:self.StatusMenu];
    [self.statusItem setHighlightMode:YES];
    
    //We need to check if APE is installed
    ApeIsInstaled = [self isApeInstalled];
    
    //For enabling/disabling manually
    [self.StatusMenu setAutoenablesItems:NO];
    
    if (ApeIsInstaled) {
        
        //This will initialize the menu
        [self switchRunningState];
        
    } else {
       
        //Message
        self.MenuItemServerState.title = @"APE Server not found !";
        
        //Disable the commands
        [self.MenuItemStartCmd setEnabled:NO];
        [self.MenuItemStopCmd setEnabled:NO];
    }
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    [self.APEtask terminate];
}

#pragma mark - UI Elements Actions

- (IBAction)startServer:(id)sender {
    
    BOOL ApeRunning = [self isApeAlreadyRunning];

    //Start only if not already running
    if (![self.APEtask isRunning] && !ApeRunning) {
        
        //We need to redefine the task everytime we launch it, so, we do this
        //to call a new server instance.
        [self defineNSTask];
        
    } else if (ApeRunning) {
        
        //Ape is running in the background (ie. not withing this app)
        //Warn the user about that
        [self warnApeAlredyRunning];
        
    }
}
- (IBAction)stopServer:(id)sender {

    //Stop only if currently running of course
    if ([self.APEtask isRunning]) {
        [self.APEtask terminate];
    }
}

#pragma mark - UI Element Management

-(void) switchRunningState
{
    //DEBUG :
    NSLog(@"Switching state --> %hhd", [self.APEtask isRunning]);
    
    //We switch the UI depending of the Task state
    if ([self.APEtask isRunning]) {
        
        //Set the UI as the server is up
        self.MenuItemServerState.title = @"APE Server Status: Aped up and running"; //TODO: Add Port number it's running on?
        [self.MenuItemStartCmd setEnabled:NO];
        [self.MenuItemStopCmd setEnabled:YES];
    } else {
        
        //Set the UI as the server is down
        self.MenuItemServerState.title = @"APE Server Status: Ape Server not running";
        [self.MenuItemStartCmd setEnabled:YES];
        [self.MenuItemStopCmd setEnabled:NO];
    }
}

# pragma mark - Utility Method

- (BOOL)isApeInstalled {
    
    //TODO...
    
    return true;
}

- (BOOL)isApeAlreadyRunning {
    
    //Check if an APE instance is already running in background using other method.
    //We do this using a bundled an NSTask and "pgrep" command.
    
    //We could also detect other background running process and manage it using switchRunningState and the stop server
    //for transparency purposes.
    
    //TODO: We could test to see if if the running instance is on the same port
    //      as we're trying to launch. Multiple Ape Instances can work at the same time on different port
    
    //Define a separate task
    NSTask *ApeCheck = [[NSTask alloc] init];
    
    //We don't need to worry for UI freeze here
    @try {
        
        //Path to aped
        NSString *path  = [NSString stringWithFormat:@"/usr/bin/pgrep"];
        
        //Arguments
        NSMutableArray *arguments = [[NSMutableArray alloc] init];
        [arguments addObject:@"aped"];
        
        //Set up the task
        ApeCheck.launchPath = path;
        ApeCheck.arguments  = arguments;
        
        //Set up an output pipe to catch the answer
        [ApeCheck setStandardOutput: [NSPipe pipe]];
        
        //Start the task
        [ApeCheck launch];
        
        //Wait until we have our answer
        [ApeCheck waitUntilExit];
        
        //Put the outpout value into a string
        NSData *taskData = [[[ApeCheck standardOutput] fileHandleForReading] availableData];
        NSString *taskDataString = [[NSString alloc] initWithData: taskData encoding: NSUTF8StringEncoding];
        
        if ([taskDataString isEqualToString:@""]) {
            
            //Ape currently not running
            return false;
            
        } else {
            
            //DEBUG:
            NSLog(@"Ape already running on PID = %@", taskDataString);
            
            //Ape is indeed running
            return true;
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Problem Running Ape Check Task: %@", [exception description]);
        return false;
    }
}

-(void) warnApeAlredyRunning
{
    //If Ape is running, the user is warned with choice of killing the background one and start a new one here it or leave it
    //running and abord launching a new one
    
    //TODO: Prompt for action and kill the process
    
    //Setup the dialog...
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    //[alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText:@"Ape Server already running"];
    [alert setInformativeText:@"Another instance of Ape Server seems to be already running in the background. Can't launch a new instance while another process is already running"];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    
    //Temp:
    [alert runModal];
    
    //Display warning and test the result
    //if ([alert runModal] == NSAlertFirstButtonReturn) {
        // OK clicked,...
        // [self killRunningApes];
        // [self startServer];
    //}
}

-(void) killRunningApes
{
    //Kill running apes using "pkill aped".
    //This need to be run as root
    //TODO...
}

#pragma mark - NSTask management

-(void) defineNSTask
{
    //Create a new task
    self.APEtask = [[NSTask alloc] init];
    
    //Dispatch the NSTask into a background process not to block the UI
    dispatch_queue_t taskQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(taskQueue, ^{
        
        @try {
            
            //Path to aped
            NSString *path  = [NSString stringWithFormat:@"/usr/bin/aped"];
            
            //Arguments
            NSMutableArray *arguments = [[NSMutableArray alloc] init];
            [arguments addObject:@"--cfg"];
            [arguments addObject:@"/etc/ape/ape.conf"];
            
            //Set up the task
            self.APEtask            = [[NSTask alloc] init];
            self.APEtask.launchPath = path;
            self.APEtask.arguments  = arguments;
            
            //Start the task
            [self.APEtask launch];
            
            //Switch the buttons state
            [self switchRunningState];
            
            //Wait until the task end
            [self.APEtask waitUntilExit];
        }
        @catch (NSException *exception) {
            NSLog(@"Problem Running Task: %@", [exception description]);
        }
        @finally {
            
            //The task is done, switch back state
            [self switchRunningState];
        }
    });
}

@end
