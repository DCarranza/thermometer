//
//  NetworkManager.m
//  Thermometer
//
//  Created by Diego Carranza on 9/26/14.
//  Copyright (c) 2014 tufts.edu. All rights reserved.
//

#import "NetworkManager.h"

NSTimeInterval TIMEOUT_IN_SECONDS = 5.0;

@implementation NetworkManager

- (id) init{
    self = [super init];
    self.configObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    self.configObject.timeoutIntervalForRequest = TIMEOUT_IN_SECONDS;
    self.defaultSession = [NSURLSession sessionWithConfiguration:self.configObject
                                                        delegate:nil
                                                   delegateQueue:[NSOperationQueue mainQueue]];
    return self;
}

- (id) initWithIPAddress: (NSURL*) ipAddress{
    self = [[NetworkManager alloc] init];
    self.ipAddress = ipAddress;
    return self;
}

- (void) establishConnection: (CompletionBlock) toCompleteWith{
    NSURLSessionDataTask * dataTask = [self.defaultSession dataTaskWithURL:self.ipAddress
                                                         completionHandler:^(NSData* data,
                                                                             NSURLResponse* response,
                                                                             NSError* error) {
                                                             
                                                             toCompleteWith(data, error);
                                                             
                                                         }];
    [dataTask resume];
}

@end