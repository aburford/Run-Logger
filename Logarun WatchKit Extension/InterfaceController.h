//
//  InterfaceController.h
//  Logarun WatchKit Extension
//
//  Created by Andrew Burford on 4/27/16.
//  Copyright © 2016 Andrew Burford. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>
#import "LARSessionDelegateProtocol.h"
@import HealthKit;

@interface InterfaceController : WKInterfaceController <LARSessionDelegateProtocol>


@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *mileageLabel;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfacePicker *hoursPicker;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfacePicker *minutesPicker;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfacePicker *secondsPicker;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *dayTitleLbl;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *dailyNoteLbl;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceButton *setDayTitleButton;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceButton *setDailyNoteButton;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceButton *postRunButton;


-(void)newResultReturned:(NSMutableDictionary*)result;
-(void)newNumberReturned:(NSString*)numberStr;

@end
