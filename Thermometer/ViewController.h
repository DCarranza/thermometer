//
//  ViewController.h
//  Thermometer
//
//  Created by Diego Carranza on 9/26/14.
//  Copyright (c) 2014 tufts.edu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

// Temperatures
@property (nonatomic, weak) IBOutlet UILabel *largeDisplayTemp;
@property (nonatomic, weak) IBOutlet UILabel *sub1DisplayTemp;
@property (nonatomic, weak) IBOutlet UILabel *sub2DisplayTemp;

// Temperature labels
@property (nonatomic, weak) IBOutlet UILabel *sub1DisplayLabel;
@property (nonatomic, weak) IBOutlet UILabel *sub2DisplayLabel;

@end
