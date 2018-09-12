//
//  EditRunRootController.m
//  Logarun
//
//  Created by Andrew Burford on 5/18/16.
//  Copyright © 2016 Andrew Burford. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EditRunRootController.h"

@implementation EditRunRootController {
    
}

-(void)runPosted {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self navigationController] popViewControllerAnimated:YES];
    });
}

-(void)viewDidLoad {
    UIPageControl *pageControl = [UIPageControl appearance];
    pageControl.pageIndicatorTintColor = [UIColor lightGrayColor];
    pageControl.currentPageIndicatorTintColor = [UIColor blackColor];
    pageControl.backgroundColor = [UIColor colorWithRed:0.99 green:1.00 blue:0.84 alpha:1.0];
    
    self.navigationTitle.title = _dateString;
    
    self.PageViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"PageViewController"];
    self.PageViewController.dataSource = self;
    
    self.page0 = [[MultipleRunsViewController alloc] init];
    TabBarController *theController = (TabBarController*)self.tabBarController;
    self.page0.healthStore = theController.healthStore;
    self.page0.runDate = _runDate;
    [self.page0 setRun:self.theRun];
    
    self.page1 = [self.storyboard instantiateViewControllerWithIdentifier:@"FirstPageController"];
    [self.page1 setRun:_theRun];
    self.page1.runDate = _runDate;
    
    self.page2 = [self.storyboard instantiateViewControllerWithIdentifier:@"SecondPageController"];
    self.page2.theRun = _theRun;
    self.page2.runDate = _runDate;
  
    NSArray *tempArray = @[self.page1];
    [self.PageViewController setViewControllers:tempArray direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    
    // Change the size of page view controller
    self.PageViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, 317);
    
    [self addChildViewController:self.PageViewController];
    [self.view addSubview:self.PageViewController.view];
    [self.PageViewController didMoveToParentViewController:self];
}

- (IBAction)saveButtonTapped:(id)sender {
    TabBarController *theController = (TabBarController*)self.tabBarController;
    [self.page0 updateArrProperties];
    if (self.page2.theTableController.shoeKeyProperty == nil) {
        //page2 was not loaded
        BOOL __block waitForWeight = false;
        BOOL __block waitForFat = false;
        NSUserDefaults *defaults = [[NSUserDefaults standardUserDefaults] init];
        BOOL autoPostHealthStuff = [defaults boolForKey:@"phone-health"];
        if ([_theRun.weight isEqualToString:@"0.00"] && (theController.healthStore) && autoPostHealthStuff) {
            waitForWeight = true;
            // query for most recent body mass
            NSDate *endDate = [_runDate dateByAddingTimeInterval:60*60*24];
            NSDate *startDate = [NSDate distantPast];
            HKSampleType *sampleType = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
            NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionNone];
            HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:sampleType predicate:predicate limit:HKObjectQueryNoLimit sortDescriptors:nil resultsHandler:^(HKSampleQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable results, NSError * _Nullable error) {
                waitForWeight = false;
                _theRun.weight = [NSString stringWithFormat:@"%.2lf",[((HKQuantitySample*)results.lastObject).quantity doubleValueForUnit:[HKUnit poundUnit]]];
                if (!waitForFat) {
                    [theController.theSession postRunOnDate:_dateString dayTitle:self.page1.dayTitleField.text distances:self.page0.distances durations:self.page0.durations dailyNote:self.page1.dailyNoteView.text delegate:self shoeKey:_theRun.shoeKey weight:_theRun.weight morningPulse:_theRun.morningPulse sleepHours:_theRun.sleepHours averageHeartRate:_theRun.averageHeartRate percentBodyFat:_theRun.percentBodyFat eventValidation:self.theRun.eventValidation viewState:self.theRun.viewState attempt:1];
                }
            }];
            [theController.healthStore executeQuery:query];
        }
        if ([_theRun.percentBodyFat isEqualToString:@"0.00"] && (theController.healthStore) && autoPostHealthStuff) {
            waitForFat = true;
            // query for most recent percent body fat
            NSDate *endDate = [_runDate dateByAddingTimeInterval:60*60*24];
            NSDate *startDate = [NSDate distantPast];
            HKSampleType *sampleType = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyFatPercentage];
            NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionNone];
            HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:sampleType predicate:predicate limit:HKObjectQueryNoLimit sortDescriptors:nil resultsHandler:^(HKSampleQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable results, NSError * _Nullable error) {
                waitForFat = false;
                _theRun.percentBodyFat = [NSString stringWithFormat:@"%.2lf",[((HKQuantitySample*)results.firstObject).quantity doubleValueForUnit:[HKUnit percentUnit]] * 100];
                if (!waitForWeight) {
                    [theController.theSession postRunOnDate:_dateString dayTitle:self.page1.dayTitleField.text distances:self.page0.distances durations:self.page0.durations dailyNote:self.page1.dailyNoteView.text delegate:self shoeKey:_theRun.shoeKey weight:_theRun.weight morningPulse:_theRun.morningPulse sleepHours:_theRun.sleepHours averageHeartRate:_theRun.averageHeartRate percentBodyFat:_theRun.percentBodyFat eventValidation:self.theRun.eventValidation viewState:self.theRun.viewState attempt:1];
                }
            }];
            [theController.healthStore executeQuery:query];
        }
        if (!waitForFat && !waitForWeight) {
            [theController.theSession postRunOnDate:_dateString dayTitle:self.page1.dayTitleField.text distances:self.page0.distances durations:self.page0.durations dailyNote:self.page1.dailyNoteView.text delegate:self shoeKey:_theRun.shoeKey weight:_theRun.weight morningPulse:_theRun.morningPulse sleepHours:_theRun.sleepHours averageHeartRate:_theRun.averageHeartRate percentBodyFat:_theRun.percentBodyFat eventValidation:self.theRun.eventValidation viewState:self.theRun.viewState attempt:1];
        } 
    } else {
        //page2 was loaded
        [theController.theSession postRunOnDate:_dateString dayTitle:self.page1.dayTitleField.text distances:self.page0.distances durations:self.page0.durations dailyNote:self.page1.dailyNoteView.text delegate:self shoeKey:self.page2.theTableController.shoeKeyProperty weight:self.page2.weightField.text morningPulse:self.page2.morningPulseField.text sleepHours:self.page2.sleepHoursField.text averageHeartRate:self.page2.averageHRField.text percentBodyFat:self.page2.percentBodyFatField.text eventValidation:self.theRun.eventValidation viewState:self.theRun.viewState attempt:1];
    }
    
    
    
    
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityIndicator.frame = CGRectMake(0, 0, 20, 20);
    UIBarButtonItem *activity = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
    [[self navigationItem] setRightBarButtonItem:activity];
    [activityIndicator startAnimating];
}


#pragma mark - No of Pages Methods
-(UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    if ([viewController isKindOfClass:[EditViewController class]]) {
        return self.page2;
    } else if ([viewController isKindOfClass:[MultipleRunsViewController class]]) {
        return self.page1;
    } else {
        return nil;
    }
}

-(UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    if ([viewController isKindOfClass:[EditView2Controller class]]) {
        return self.page1;
    } else if ([viewController isKindOfClass:[EditViewController class]]) {
        return self.page0;
    } else {
        return nil;
    }
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController
{
    return 3;
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController
{
    return 1;
}



@end
