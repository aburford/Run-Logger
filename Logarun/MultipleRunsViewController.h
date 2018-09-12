//
//  MultipleRunsViewController.h
//  Run Logger
//
//  Created by Andrew Burford on 10/1/16.
//  Copyright © 2016 Andrew Burford. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LARRun.h"
@import HealthKit;

@interface MultipleRunsViewController : UIViewController <UITextFieldDelegate>

@property (copy) NSMutableArray *distances;
@property (copy) NSMutableArray *durations;
@property (copy) NSDate *runDate;
@property (nonatomic) HKHealthStore *healthStore;

-(void)setRun:(LARRun*)newRun;
-(void)updateArrProperties;

@end
