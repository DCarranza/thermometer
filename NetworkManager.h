//
//  NetworkManager.h
//  Thermometer
//
//  Created by Diego Carranza on 9/26/14.
//  Copyright (c) 2014 tufts.edu. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef void (^ CompletionBlock) (NSData *data, NSError *error);


@interface NetworkManager : NSObject
@property (nonatomic, strong) NSURLSessionConfiguration *configObject;
@property (nonatomic, strong) NSURLSession* defaultSession;
@property (nonatomic, strong) NSURL* ipAddress;

- (id) initWithIPAddress: (NSURL*) ipAddress;
- (void) establishConnection: (CompletionBlock) toCompleteWith;

@end
