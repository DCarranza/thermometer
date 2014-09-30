//
//  ViewController.m
//  Thermometer
//
//  Created by Diego Carranza on 9/26/14.
//  Copyright (c) 2014 tufts.edu. All rights reserved.
//

#import "ViewController.h"
#import "NetworkManager.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

//Globals
NSString* URL = @"http://10.3.14.92/";
//The arduino can't serve 1000 samples at anything less than
// 1.3 seconds.
double_t WAIT_TIME = 1.3;

//Private variables
@interface ViewController()
//This has been typedef'd in NetworkManager.h
@property (nonatomic, copy) CompletionBlock completionBlock;
//This is the model!
//The JSON will be stored as such {"current:float", "one:float", "ten:float"}
@property (nonatomic, strong) NSDictionary* temperatureStore;
@property (nonatomic, strong) NetworkManager* netManager;
@property (nonatomic, strong) NSURL* ipAddress;
@property (nonatomic, assign) NSInteger retryCounter;
@property (nonatomic, strong) AVAudioPlayer *player;
@end


@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initalizeCompletionBlock];
    self.retryCounter = 0;
    self.ipAddress =[NSURL URLWithString:URL];
    self.netManager = [[NetworkManager alloc] initWithIPAddress:self.ipAddress];
    
    //Run network code
    [self.netManager establishConnection:self.completionBlock];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) initalizeCompletionBlock{
    self.completionBlock = ^void(NSData* data, NSError* error){
        if(!error){
            NSLog(@"Connection Successful.");
            self.retryCounter = 0;
            [self storeDataAsJSON:data with:error];
            //Reload UI
            //This call takes care of the sleeping
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, WAIT_TIME * NSEC_PER_SEC),
                           dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                           ^(){
                               [self.netManager establishConnection:self.completionBlock];
                           });
            
        }
        else{
            self.retryCounter++;
            NSLog(@"There was an error: %u.", self.retryCounter);
            if(self.retryCounter <3)
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, WAIT_TIME * NSEC_PER_SEC),
                               dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                               ^(){
                                   [self.netManager establishConnection:self.completionBlock];
                               });
        }
    };
    
}

- (void) storeDataAsJSON:(NSData*) data with:(NSError*) error{
    self.temperatureStore = [NSJSONSerialization JSONObjectWithData:data
                                                            options:kNilOptions error:&error];
    NSLog(@"%@", self.temperatureStore);

}
- (void) setUpAlarm{
    NSString *soundFilePath = [NSString stringWithFormat:@"%@/alarm.mp3",
                               [[NSBundle mainBundle] resourcePath]];
    NSLog(@"%@",soundFilePath);
    NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];
    NSLog(@"%@", soundFileURL);
    
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL
                                                         error:nil];
    [self.player setVolume:1.0];
    self.player.numberOfLoops = -1; //Infinite
}

//Call this to start alarm
//The alarm will not stop until
// stopAlarm is called.
- (void) playAlarm{
    [self.player play];
}

//Stops the alarm.
- (void) stopAlarm{
    [self.player stop];
}

@end


















