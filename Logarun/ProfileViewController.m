//
//  ProfileViewController.m
//  Logarun
//
//  Created by Andrew Burford on 5/12/16.
//  Copyright © 2016 Andrew Burford. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ProfileViewController.h"

@implementation ProfileViewController {
    NSArray *cellTitles;
    NSString *totMileage;
    UIActivityIndicatorView *activityView;
    UILabel *mileageLabel;
    UILabel *mileageLeftLabel;
    UILabel *mileagePlanLabel;
    BOOL userAlreadyRan;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath indexAtPosition:0] == 1 && [indexPath indexAtPosition:1] == 0) {
        return 100.0f;
    } else {
        return 44.0f;
    }
}

-(void)didReceiveMileage:(double)weeklyMileage userAlreadyRan:(bool)alreadyRan{
    if (weeklyMileage != -1) {
        userAlreadyRan = alreadyRan;
        totMileage = [NSString stringWithFormat:@"%.2lf miles",weeklyMileage];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    } else {
        // request timed out
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Connection Error"
                                                                       message:@"Unable to connect to LogARun servers. Please check your network connection."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* retryAction = [UIAlertAction actionWithTitle:@"Retry" style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction * action) {
                                                                [self.tableView reloadData];
                                                            }];
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction * action) {
                                                                [activityView stopAnimating];
                                                            }];
        [alert addAction:defaultAction];
        [alert addAction:retryAction];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self presentViewController:alert animated:YES completion:nil];
        });

    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch ([indexPath indexAtPosition:0]) {
        case 0:
        {
            UITableViewCell *theCell = [tableView dequeueReusableCellWithIdentifier:@"tableViewCell"];
            theCell.textLabel.text = [cellTitles objectAtIndex:[indexPath indexAtPosition:1]];
            return theCell;
        }
            break;
        case 1:
        {
            UITableViewCell *theCell = [tableView dequeueReusableCellWithIdentifier:@"mileageCell"];
            int cellWidth = self.view.window.frame.size.width;
            int cellHeight = 140;
            if (totMileage) {
                [activityView stopAnimating];
                if (!mileageLabel) {
                    mileageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, cellHeight / 4, cellWidth, 20)];
                    mileageLabel.textAlignment = NSTextAlignmentCenter;
                    
                    mileageLeftLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, cellHeight / 4 + 20, cellWidth, 20)];
                    mileageLeftLabel.textAlignment = NSTextAlignmentCenter;
                    
                    mileagePlanLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, cellHeight / 4 + 40 , cellWidth, 20)];
                    mileagePlanLabel.numberOfLines = 0;
                    mileagePlanLabel.lineBreakMode = NSLineBreakByTruncatingTail;
                    mileagePlanLabel.textAlignment = NSTextAlignmentCenter;
                    
                    [theCell.contentView addSubview:mileageLabel];
                    [theCell.contentView addSubview:mileageLeftLabel];
                    [theCell.contentView addSubview:mileagePlanLabel];
                }
                [mileageLabel setHidden:0];
                [mileageLeftLabel setHidden:0];
                [mileagePlanLabel setHidden:0];
                
                mileageLabel.text = totMileage;
                
                NSUserDefaults *defaults = [[NSUserDefaults standardUserDefaults] init];
                double mileageLeft = [defaults doubleForKey:@"mileage-goal"] - [totMileage doubleValue];
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setDateFormat:@"e"];
                int dayIndex = (int)[[dateFormatter stringFromDate:[NSDate date]] integerValue];
                if ([[defaults objectForKey:@"firstDayOfWeek"] isEqualToString:@"1"]) {
                    // make adjustment because first day of week is monday
                    switch (dayIndex) {
                        case 1:
                            dayIndex = 7;
                            break;
                        default:
                            dayIndex -=1;
                            break;
                    }
                }
                int daysLeft = 8 - dayIndex;
                if (userAlreadyRan) {
                    daysLeft--;
                }
                if (mileageLeft <= 0) {
                    mileageLeftLabel.text = @"";
                    mileagePlanLabel.text = @"Good job, you hit your mileage goal!";
                } else {
                    mileagePlanLabel.text = @"";
                    switch (daysLeft) {
                        case 0:
                            mileageLeftLabel.text = [NSString stringWithFormat:@"You were %.2lf miles short this week",mileageLeft];
                            break;
                        case 1:
                            if (userAlreadyRan) {
                                mileageLeftLabel.text = [NSString stringWithFormat:@"%.2lf more miles to run tomorrow",mileageLeft];
                            } else {
                                mileageLeftLabel.text = [NSString stringWithFormat:@"%.2lf more miles to run today",mileageLeft];
                            }
                            break;
                        default:
                            mileageLeftLabel.text = [NSString stringWithFormat:@"%.2lf more miles to run in %d days",mileageLeft,daysLeft];
                            mileagePlanLabel.text = [NSString stringWithFormat:@"Run %.2lf miles a day to hit goal",mileageLeft / (double)daysLeft];
                            break;
                    }
                }
            } else {
                if (!activityView) {
                    activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
                    activityView.hidesWhenStopped = true;
                    activityView.frame = CGRectMake(0, cellHeight / 2 - 10, cellWidth, 20);
                    [theCell.contentView addSubview:activityView];
                }
                [mileageLabel setHidden:1];
                [mileageLeftLabel setHidden:1];
                [mileagePlanLabel setHidden:1];
                
                [activityView startAnimating];
                TabBarController *theController = (TabBarController*)self.tabBarController;
                
                // get the current mileage
                [theController.theSession getCurrentMileageToDelegate:self];
            }
            return theCell;
        }
            break;
        case 2:
        {
            UITableViewCell *theCell = [tableView dequeueReusableCellWithIdentifier:@"tableViewCell"];
            switch ([indexPath indexAtPosition:1]) {
                case 0:
                    theCell.textLabel.text = @"Settings";
                    break;
                case 1:
                    theCell.textLabel.text = @"Help/About";
                default:
                    break;
            }
            return theCell;
        }
            break;
        default:
            NSLog(@"whoops");
            return [[UITableViewCell alloc] init];
            break;
    }
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title;
    switch (section) {
        case 0:
            title = @"Logarun Account";
            break;
        case 1:
            title = @"Mileage";
            break;
        case 2:
            title = @"";
            break;
        default:
            title = @"";
            break;
    }
    return title;
}

-(NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSString *title;
    switch (section) {
        case 0:
            title = @"";
            break;
        case 1:
            title = @"";
            break;
        case 2:
            title = [NSString stringWithFormat:@"Run Logger %@ by Andrew Burford",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
            break;
        default:
            title = @"";
            break;
    }
    return title;
}

-(void)viewDidLoad {
    
    [super viewDidLoad];
    self.clearsSelectionOnViewWillAppear = YES;
    TabBarController *theController = (TabBarController*)self.tabBarController;
    [self.navigationItem setTitle:[NSString stringWithFormat:@"Profile - %@",theController.theSession.username]];
    cellTitles = @[@"General Info",@"Shoes",@"Account Preferences",@"Log Out"];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return [cellTitles count];
            break;
        case 1:
            return 1;
            break;
        case 2:
            return 2;
        default:
            NSLog(@"hhhwwwhat??");
            return 0;
            break;
    }
    
    
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath indexAtPosition:0] == 0) {
        if ([indexPath indexAtPosition:1] == 0) {
            // general info
            [self performSegueWithIdentifier:@"toGeneralInfo" sender:self];
        } else if ([indexPath indexAtPosition:1] == 1) {
            // shoes
            [self performSegueWithIdentifier:@"toShoesView" sender:self];
        } else if ([indexPath indexAtPosition:1] == 2) {
            // account preferences
            [self performSegueWithIdentifier:@"toAccountPreferences" sender:self];
        } else if ([indexPath indexAtPosition:1] == 3) {
            // logout
            [((TabBarController*)self.tabBarController).theSession logout];
            // go back to login view
            [self performSegueWithIdentifier:@"logoutSegue" sender:self];
        }
    } else if ([indexPath indexAtPosition:0] == 1) {
        totMileage = nil;
        [self.tableView reloadData];
    } else if ([indexPath indexAtPosition:0] == 2) {
        switch ([indexPath indexAtPosition:1]) {
            case 0:
                [self performSegueWithIdentifier:@"toSettings" sender:self];
                break;
            case 1:
                [self performSegueWithIdentifier:@"toAbout" sender:self];
                break;
            default:
                break;
        }
    }
}

-(void)viewDidLayoutSubviews {
    if (mileageLabel && activityView) {
        int cellWidth = self.view.window.frame.size.width;
        int cellHeight = 140;
        mileagePlanLabel.frame = CGRectMake(0, cellHeight / 4 + 40 , cellWidth, 20);
        mileageLabel.frame = CGRectMake(0, cellHeight / 4, cellWidth, 20);
        mileageLeftLabel.frame = CGRectMake(0, cellHeight / 4 + 20, cellWidth, 20);
        activityView.frame = CGRectMake(0, cellHeight / 2 - 10, cellWidth, 20);
    }
}

@end
