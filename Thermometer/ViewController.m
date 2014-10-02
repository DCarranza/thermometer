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
NSString* URL = @"http://10.3.14.183/";
//The arduino can't serve 1000 samples at anything less than
// 1.3 seconds.
double_t WAIT_TIME = 1.3;
float CONVERSION_SLOPE = .4382;
float CONVERSION_OFFSET = 7.3;//.35;

//Private variables
@interface ViewController()
//This has been typedef'd in NetworkManager.h
@property (nonatomic, copy) CompletionBlock completionBlock;
//This is the model!
//The JSON will be stored as such {"current:float", "one:float", "ten:float"}
@property (nonatomic, strong) NSMutableDictionary* temperatureStore;
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
    
    // Temperature labels
    self.sub1DisplayLabel.text = @"current read";
    self.sub2DisplayLabel.text = @"10s average";
    
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
            NSNumber* tempCurrent = [self.temperatureStore objectForKey:@"current"];
            NSNumber* tempOneSecondAvg = [self.temperatureStore objectForKey:@"one"];
            NSNumber* tempTenSecondAvg = [self.temperatureStore objectForKey:@"ten"];
            NSLog(@"current is %@",tempCurrent);
            NSLog(@"onesec is %@", tempOneSecondAvg);
            [self setUITemps:tempOneSecondAvg with:tempCurrent with:tempTenSecondAvg];
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
            if(self.retryCounter <10)
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, WAIT_TIME * NSEC_PER_SEC),
                               dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                               ^(){
                                   [self.netManager establishConnection:self.completionBlock];
                               });
        }
    };
    
}

- (void) storeDataAsJSON:(NSData*) data with:(NSError*) error{
    NSDictionary* rawData = [NSJSONSerialization JSONObjectWithData:data
                                                            options:kNilOptions error:&error];
    NSLog(@"Unconverted %@", rawData);
    [self convertToF:rawData];
   }

- (void) convertToF: (NSDictionary *)rawData{
    self.temperatureStore = [rawData mutableCopy];
    float current = [[self.temperatureStore objectForKey:@"current"] floatValue];
    float oneSecondAverage = [[self.temperatureStore objectForKey:@"one"] floatValue];
    float tenSecondAverage = [[self.temperatureStore objectForKey:@"ten"] floatValue];
    
    //Convert to F
    NSLog(@"Unconvrted current %f", current);
    current = current*CONVERSION_SLOPE + CONVERSION_OFFSET;
    oneSecondAverage = oneSecondAverage*CONVERSION_SLOPE + CONVERSION_OFFSET;
    tenSecondAverage = tenSecondAverage*CONVERSION_SLOPE + CONVERSION_OFFSET;
    
    //Store
    [self.temperatureStore setObject:[NSNumber numberWithFloat:current]
                              forKey:@"current"];
    [self.temperatureStore setObject:[NSNumber numberWithFloat:oneSecondAverage]
                              forKey:@"one"];
    [self.temperatureStore setObject:[NSNumber numberWithFloat:tenSecondAverage]
                              forKey:@"ten"];
    NSLog(@"This is the converted! %@",self.temperatureStore);
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


/*
 UI Methods
 - Methods that control single-page view
 */

// Sets all of the temperature reads
// - @param currDisplayToSet : The current temperature display will display this NSNumber
// - @param oneSecDisplayToSet : The one-second temperature display will display this NSNumber
// - @param tenSecDisplayToSet : The ten-second avg. temperature display will display this NSNumber
- (void) setUITemps: (NSNumber*) toSetLargeTemp with: (NSNumber*) toSetSub1Temp with: (NSNumber*) toSetSub2Temp {
    
    // Set the temperature displays
    self.largeDisplayTemp.text = [NSString stringWithFormat:@"%.01f", [toSetLargeTemp floatValue]];
    self.sub1DisplayTemp.text = [NSString stringWithFormat:@"%.01f", [toSetSub1Temp floatValue]];
    self.sub2DisplayTemp.text = [NSString stringWithFormat:@"%.01f", [toSetSub2Temp floatValue]];
}

// Starts the alarm
- (void) startUIAlarm {
    [self playAlarm];
}

// Stops the alarm
- (void) stopUIAlarm {
    [self stopAlarm];
}

@end


















