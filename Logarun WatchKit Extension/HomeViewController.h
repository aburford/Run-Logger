//
//  HomeViewController.h
//  Logarun
//
//  Created by Andrew Burford on 6/15/16.
//  Copyright © 2016 Andrew Burford. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>
#import "LARSessionDelegateProtocol.h"
#import "LARWatchSession.h"
@import Security;
@import WatchConnectivity;

@interface HomeViewController : WKInterfaceController <LARSessionDelegateProtocol, WCSessionDelegate>

@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceButton *editRunButton;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceSeparator *firstSeparator;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceImage *ringImage;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *graphTitleLbl;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *mileageLbl;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *refreshingLbl;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceButton *refreshMileageButton;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *pleaseLoginLabel;

@property (nonatomic) WCSession *watchSession;

-(void)didReceiveMileage:(double)weeklyMileage userAlreadyRan:(bool)alreadyRan;

@end
