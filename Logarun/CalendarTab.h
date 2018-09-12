//
//  CalendarTab.h
//  Logarun
//
//  Created by Andrew Burford on 5/9/16.
//  Copyright © 2016 Andrew Burford. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PDTSimpleCalendarViewController.h"
#import "EditViewController.h"
#import "LARSession.h"
#import "LARSessionDelegateProtocol.h"
#import "TabBarController.h"
#import "EditRunRootController.h"
//#import <StartApp/StartApp.h>
#import "PDTSimpleCalendarViewCell.h"

@interface CalendarTab : UIViewController <PDTSimpleCalendarViewDelegate,LARSessionDelegateProtocol>

@property (nonatomic, weak) PDTSimpleCalendarViewController *calendarView;
@property (copy) LARSession *theSession;
@property (weak, nonatomic) IBOutlet UILabel *dayTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *durationLabel;
@property (weak, nonatomic) IBOutlet UILabel *distanceLabel;
@property (weak, nonatomic) IBOutlet UILabel *paceLabel;
@property (weak, nonatomic) IBOutlet UITextView *noteTextView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIView *calendarContainerView;

- (void)simpleCalendarViewController:(PDTSimpleCalendarViewController *)controller didSelectDate:(NSDate *)date;
- (BOOL)simpleCalendarViewController:(PDTSimpleCalendarViewController *)controller isEnabledDate:(NSDate *)date;
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender;
-(void)didReceiveRun:(LARRun *)theRun forDate:(NSDate *)theDate;
-(void)didReceiveMileage:(double)weeklyMileage userAlreadyRan:(bool)alreadyRan;


@end
