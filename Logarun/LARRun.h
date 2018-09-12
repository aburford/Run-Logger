//
//  LARRun.h
//  Logarun
//
//  Created by Andrew Burford on 5/12/16.
//  Copyright © 2016 Andrew Burford. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LARRun : NSObject

@property (copy) NSString *dayTitle;
@property (copy) NSString *note;

@property (copy) NSString *totalDistance;
@property (copy) NSString *totalDuration;
@property (copy) NSArray<NSString*>* distances;
@property (copy) NSArray<NSString*>* durations;
@property (copy) NSArray<NSString*>* paces;

@property (copy) NSString *weight;
@property (copy) NSString *morningPulse;
@property (copy) NSString *sleepHours;
@property (copy) NSString *averageHeartRate;
@property (copy) NSString *percentBodyFat;
@property (copy) NSString *shoeKey;

@property (copy) NSMutableArray *commentersArr;
@property (copy) NSMutableArray *commentsArr;

@property (copy) NSString *eventValidation;
@property (copy) NSString *viewState;
@property (copy) NSString *commentURL;

@end
