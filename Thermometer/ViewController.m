//
//  ViewController.m
//  Thermometer
//
//  Created by Diego Carranza on 9/26/14.
//  Copyright (c) 2014 tufts.edu. All rights reserved.
//

#import "ViewController.h"
#import "NetworkManager.h"

//Globals
NSString* URL = @"http://www.google.com";
int WAIT_TIME = 1;

//Private variables
@interface ViewController()
//This has been typedef'd in NetworkManager.h
@property (nonatomic, copy) CompletionBlock completionBlock;
//This is the model!
@property (nonatomic, strong) NSMutableArray* temperatureStore;
@property (nonatomic, strong) NetworkManager* netManager;
@property (nonatomic, strong) NSURL* ipAddress;
@property (nonatomic, assign) NSInteger retryCounter;
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
            NSLog(@"There was no error.");
            self.retryCounter = 0;
            //Save to model code
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
            if(self.retryCounter <=5)
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, WAIT_TIME * NSEC_PER_SEC),
                               dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                               ^(){
                                   [self.netManager establishConnection:self.completionBlock];
                               });
        }
    };
    
}

@end

