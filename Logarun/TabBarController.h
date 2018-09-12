//
//  TabBarController.h
//  Logarun
//
//  Created by Andrew Burford on 5/12/16.
//  Copyright © 2016 Andrew Burford. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LARSession.h"
@import HealthKit;

@interface TabBarController : UITabBarController

@property (nonatomic) LARSession *theSession;
@property (nonatomic) HKHealthStore *healthStore;

-(void)setLARSession:(LARSession*)session;

@end
