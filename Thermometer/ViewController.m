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
NSString* URL = @"http://10.3.14.213/";
//The arduino can't serve 1000 samples at anything less than
// 1.3 seconds.
double_t WAIT_TIME = 1.3;
float CONVERSION_SLOPE = .4382;
float CONVERSION_OFFSET = 9.3;//.35;

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

// Temperature property
@property (nonatomic, assign) BOOL toFaren;
@property (nonatomic, assign) BOOL isFaren;
@property (nonatomic, assign) BOOL ableConvert;

// Temperature threshold
@property (nonatomic, assign) double alarmThresh;
@property (nonatomic, assign) BOOL shouldAlarm;
@property (nonatomic, assign) BOOL isAlarming;
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
    self.sub1DisplayLabel.text = @"(CURR)";
    self.sub2DisplayLabel.text = @"(10s)";
    
    // Temperature F or C
    self.toFaren = YES;
    self.isFaren = YES;
    self.ableConvert = NO;
    
    // Set threshold for alarm, set up alarm
    self.alarmThresh = 90;
    self.shouldAlarm = YES;
    self.isAlarming = NO;
    [self setUpAlarm];
    
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
            
            // Send an alert to the user
            UIAlertView* retryAlert = [[UIAlertView alloc] initWithTitle:@"Something went wrong..." message:@"Ensure the device and wireless network are on." delegate:self cancelButtonTitle:@"Retry" otherButtonTitles:nil];
            [retryAlert show];
            
            if(self.retryCounter <100)
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
    self.isAlarming = YES;
}

//Stops the alarm.
- (void) stopAlarm{
    [self.player stop];
    self.isAlarming = NO;
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
    
    // Activate alarm if temperature is high enough
    if (!self.isAlarming && ([toSetLargeTemp doubleValue] >= self.alarmThresh) && self.shouldAlarm) {
        [self startUIAlarm];
    }
    // Reactivate alarm when goes below threshold
    else if (([toSetLargeTemp doubleValue] < self.alarmThresh)) {
        self.shouldAlarm = YES;
        [self stopUIAlarm];
    }
    
    // Set the temperature displays
    self.largeDisplayTemp.text = [NSString stringWithFormat:@"%.01f", [toSetLargeTemp floatValue]];
    self.sub1DisplayTemp.text = [NSString stringWithFormat:@"%.01f", [toSetSub1Temp floatValue]];
    self.sub2DisplayTemp.text = [NSString stringWithFormat:@"%.01f", [toSetSub2Temp floatValue]];
    
    self.ableConvert = YES;
    self.isFaren = YES;
    [self convertTemp];
    
}

// Starts the alarm
- (void) startUIAlarm {
    [self playAlarm];
    self.view.backgroundColor = [UIColor colorWithRed:166.0/256.0 green:63.0/256.0 blue:66.0/256.0 alpha:1.0];
    
    // Set the image
    [self.dismissAlarmControl setImage:[UIImage imageNamed:@"DismissButton.png"] forState:UIControlStateNormal];
}

// Stops the alarm
- (void) stopUIAlarm {
    [self stopAlarm];
    self.view.backgroundColor = [UIColor colorWithRed:63.0/256.0 green:166.0/256.0 blue:126.0/256.0 alpha:1.0];
    
    // Set the image
    [self.dismissAlarmControl setImage:[UIImage imageNamed:@"DismissButtonInactive.png"] forState:UIControlStateNormal];
}

// Converts any Farenheit value to a Celsius value
- (float) convertFtoC: (float) toConvert {
    return (float)(toConvert-32)*(5/(float)9);
}

// Converts any Celsius value to a Farenheit value
- (float) convertCtoF: (float) toConvert {
    return (float)(toConvert*(9/(float)5))+32;
}

// Translates current temperature by bool
- (void) convertTemp {
    if (!self.toFaren && self.isFaren) {
        // Convert all display temperatures to celsius
        self.largeDisplayTemp.text = [NSString stringWithFormat:@"%.01f", [self convertFtoC:[self.largeDisplayTemp.text floatValue]]];
        self.sub1DisplayTemp.text = [NSString stringWithFormat:@"%.01f", [self convertFtoC:[self.sub1DisplayTemp.text floatValue]]];
        self.sub2DisplayTemp.text = [NSString stringWithFormat:@"%.01f", [self convertFtoC:[self.sub2DisplayTemp.text floatValue]]];
        
        self.isFaren = NO;
    }
    else if (self.toFaren && !self.isFaren) {
        // Convert all display temperatures to celsius
        self.largeDisplayTemp.text = [NSString stringWithFormat:@"%.01f", [self convertCtoF:[self.largeDisplayTemp.text floatValue]]];
        self.sub1DisplayTemp.text = [NSString stringWithFormat:@"%.01f", [self convertCtoF:[self.sub1DisplayTemp.text floatValue]]];
        self.sub2DisplayTemp.text = [NSString stringWithFormat:@"%.01f", [self convertCtoF:[self.sub2DisplayTemp.text floatValue]]];
        
        self.isFaren = YES;
    }
}

// IBAction method for the F/C toggle
- (IBAction)toggleTempType:(id)sender {
    if (!self.ableConvert) { return; }

    if (self.toFaren) {
        self.toFaren = NO;
    }
    else {
        self.toFaren = YES;
    }
    [self convertTemp];
}

// IBAction method for the dismiss
- (IBAction)dismissAlarm:(id)sender {
    self.shouldAlarm = NO;
    [self stopUIAlarm];
}

@end


















