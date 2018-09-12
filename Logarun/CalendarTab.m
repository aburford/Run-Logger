//
//  CalendarTab.m
//  Logarun
//
//  Created by Andrew Burford on 5/9/16.
//  Copyright © 2016 Andrew Burford. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CalendarTab.h"


@interface CalendarTab ()


@end

@implementation CalendarTab {
    NSDate *selectedDate;
    LARRun *currentRun;
    NSMutableDictionary *runsForDates;
    int syncRequestsSent;
    int syncRequestsReceived;
    int secondsPassed;
    UIActivityIndicatorView *activityView2;
    UIProgressView *progressView;
    double currentWidth;
    bool alertShowing;
}

- (IBAction)editButtonPressed:(id)sender {
    [self performSegueWithIdentifier:@"toEditView" sender:self];
}

-(void)cancelPressed {
    [_theSession cancelGetRunTasks];
    [activityView2 stopAnimating];
    [progressView setHidden:1];
    UIBarButtonItem *syncButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(syncButtonPressed:)];
    self.navigationController.navigationBar.topItem.leftBarButtonItem = syncButton;
}

- (IBAction)syncButtonPressed:(id)sender {
    // i love ads yay
    //[STAStartAppAdBasic showAd];
    
    // turn sync button into a stop button to cancel the sync
    UIBarButtonItem *stopButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(cancelPressed)];
    self.navigationController.navigationBar.topItem.leftBarButtonItem = stopButton;
    
    // cancel all other tasks in preparation of the sync
    [_theSession cancelGetRunTasks];
    [_activityIndicator stopAnimating];
    syncRequestsReceived = 0;
    
    // create the loading screen
    if (!activityView2) {
        activityView2 = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        activityView2.color = [UIColor blackColor];
        activityView2.frame = _calendarContainerView.frame;
        activityView2.backgroundColor = [UIColor colorWithHue:0.0 saturation:0.0 brightness:0.65 alpha:0.7];
        activityView2.hidesWhenStopped = true;
        [self.view addSubview:activityView2];
    }
    [activityView2 startAnimating];
    
    
    // create the progress bar
    if (!progressView) {
        progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        int yPos = activityView2.frame.origin.y + activityView2.frame.size.height / 2 + 30;
        progressView.frame = CGRectMake(self.view.window.frame.size.width / 4, yPos, self.view.window.frame.size.width / 2, 10);
        progressView.trackTintColor = [UIColor whiteColor];
        [self.view addSubview:progressView];
    }
    progressView.progress = 0.0f;
    [progressView setHidden:0];
    
    
    // minDate and maxDate represent the date range
    NSDate *minDate = _calendarView.firstDate;
    NSDate *maxDate = _calendarView.lastDate;
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *days = [[NSDateComponents alloc] init];
    NSInteger dayCount = 0;
    [_theSession getRunForDate:minDate delegate:self];
    syncRequestsSent = 1;
    while ( TRUE ) {
        [days setDay: ++dayCount];
        NSDate *date = [calendar dateByAddingComponents:days toDate:minDate options: 0];
        if ([date compare:maxDate] == NSOrderedDescending) {
            break;
        }
        [_theSession getRunForDate:date delegate:self];
        syncRequestsSent++;
    }
    
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"embeddedSegue"]) {
        
        // configure PDTSimpleCalendar
        self.calendarView = segue.destinationViewController;
        self.calendarView.delegate = self;
        NSCalendar *myCalendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
        NSUserDefaults *defaults = [[NSUserDefaults standardUserDefaults] init];
        if ([[defaults objectForKey:@"firstDayOfWeek"] isEqualToString:@"1"]) {
            // make adjustment because first day of week is monday
            myCalendar.firstWeekday = 2;
        }
        self.calendarView.calendar = myCalendar;
        
        [self.calendarView setSelectedDate:[NSDate date]];
        [self.calendarView scrollToSelectedDate:YES];
        self.calendarView.weekdayHeaderEnabled = YES;
        // set selected color green
        [[PDTSimpleCalendarViewCell appearance] setCircleSelectedColor:[UIColor colorWithRed:0.29 green:0.35 blue:0.18 alpha:1.0]];
        
    } else if ([segue.identifier isEqualToString:@"toEditView"]) {
        EditRunRootController *theEditRunRootController = segue.destinationViewController;
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"MM/dd/yyyy"];
        NSString *formattedDateString = [dateFormatter stringFromDate:selectedDate];
        theEditRunRootController.dateString = formattedDateString;
        theEditRunRootController.runDate = selectedDate;
        NSLog(@"sending edit run root controller LARRun:%@",[runsForDates objectForKey:selectedDate]);
        theEditRunRootController.theRun = [runsForDates objectForKey:selectedDate];
    }
}

-(void)didReceiveMileage:(double)weeklyMileage userAlreadyRan:(bool)alreadyRan{
    
}

- (BOOL)simpleCalendarViewController:(PDTSimpleCalendarViewController *)controller isEnabledDate:(NSDate *)date {
    return true;
}

-(void)didReceiveRun:(LARRun *)theRun forDate:(NSDate *)theDate {
    if (theRun) {
        syncRequestsReceived++;
        
        [runsForDates setObject:theRun forKey:theDate];
        if (theDate == selectedDate) {
            currentRun = theRun;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateCurrentRunView];
            });
        }
        float progress = (float)syncRequestsReceived / (float)syncRequestsSent;
        dispatch_async(dispatch_get_main_queue(), ^{
            [progressView setProgress:progress animated:YES];
        });
        if (syncRequestsReceived == 20 || syncRequestsReceived == 40) {
            dispatch_async(dispatch_get_main_queue(), ^{
                // show an ad here only if you are a despicable human being
                // [STAStartAppAdBasic showAd];
            });
        }
        if (syncRequestsReceived == syncRequestsSent) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [activityView2 stopAnimating];
                [progressView setHidden:1];
                
                // change the cancel button back to a sync button
                UIBarButtonItem *syncButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(syncButtonPressed:)];
                self.navigationController.navigationBar.topItem.leftBarButtonItem = syncButton;
            });
        }
    } else {
        NSLog(@"run request timed out");
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Connection Error"
                                                                       message:@"Unable to connect to LogARun servers. Please check your network connection."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* retryAction = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction * action) {
                                                                alertShowing = false;
                                                                [_activityIndicator stopAnimating];
                                                                [_theSession cancelGetRunTasks];
                                                                [activityView2 stopAnimating];
                                                                [progressView setHidden:1];
                                                                UIBarButtonItem *syncButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(syncButtonPressed:)];
                                                                self.navigationController.navigationBar.topItem.leftBarButtonItem = syncButton;
                                                            }];
        [alert addAction:retryAction];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self presentViewController:alert animated:YES completion:nil];
            alertShowing = true;
        });
    }
}

-(void)updateCurrentRunView {
    LARRun *theRun = [runsForDates objectForKey:selectedDate];
    _dayTitleLabel.text = theRun.dayTitle;
    // calculate total duration by adding up each duration
    __block int seconds = 0;
    [theRun.durations enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray *durationComponents = [obj componentsSeparatedByString:@":"];
        seconds += [durationComponents[2] integerValue] + [durationComponents[1] integerValue] * 60 + [durationComponents[0] integerValue] * 3600;
    }];
    int minutes = floor(seconds / 60);
    int hours = floor(minutes / 60);
    minutes = minutes % 60;
    _durationLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d",hours,minutes,seconds % 60];
    
    __block double totMiles = 0;
    [theRun.distances enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        totMiles += [obj doubleValue];
    }];
    _distanceLabel.text = [NSString stringWithFormat:@"%.2lf miles",totMiles];
    if (totMiles == 1) {
        _distanceLabel.text = [NSString stringWithFormat:@"%.2lf mile",totMiles];
    }
    // now calculate pace
    if (totMiles != 0) {
        seconds = seconds / totMiles;
        minutes = floor(seconds / 60);
        hours = floor(minutes / 60);
        _paceLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d /mile",hours,minutes % 60,seconds % 60];
    } else {
        _paceLabel.text = @"00:00:00 /mile";
    }
    _noteTextView.text = [NSString stringWithFormat:@"Daily note:\n%@",theRun.note];
    [_activityIndicator stopAnimating];
}

- (void)simpleCalendarViewController:(PDTSimpleCalendarViewController *)controller didSelectDate:(NSDate *)date {
    selectedDate = date;
    
    if (![runsForDates objectForKey:date]) {
        // run has not yet been downloaded, start loading it now
        [_theSession getRunForDate:date delegate:self];
        [_activityIndicator startAnimating];
        
    } else {
        [self updateCurrentRunView];
    }
}

-(void)viewDidLoad {
    NSLog(@"calendar tab loaded");
    [super viewDidLoad];
    alertShowing = false;
    TabBarController *theController = (TabBarController*)self.tabBarController;
    _theSession = theController.theSession;
    runsForDates = [[NSMutableDictionary alloc] init];
}

-(void)viewDidAppear:(BOOL)animated {
    [_theSession getRunForDate:selectedDate delegate:self];
    [_activityIndicator startAnimating];
    
    NSUserDefaults *defaults = [[NSUserDefaults standardUserDefaults] init];
    if ([[defaults objectForKey:@"firstDayOfWeek"] isEqualToString:@"1"]) {
        // make adjustment because first day of week is monday
        self.calendarView.calendar.firstWeekday = 2;
    } else {
        self.calendarView.calendar.firstWeekday = 1;
    }
    [self.calendarView.collectionView reloadData];
}

-(void)viewDidLayoutSubviews {
    activityView2.frame = _calendarContainerView.frame;
    progressView.frame = CGRectMake(self.view.window.frame.size.width / 4, activityView2.frame.origin.y + activityView2.frame.size.height / 2 + 30, self.view.window.frame.size.width / 2, 10);
    
}

@end
