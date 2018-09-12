//
//  MultipleRunsViewController.m
//  Run Logger
//
//  Created by Andrew Burford on 10/1/16.
//  Copyright © 2016 Andrew Burford. All rights reserved.
//

#import "MultipleRunsViewController.h"

@interface MultipleRunsViewController () {
    UIScrollView *scrollView;
    NSMutableArray<UITextField*> *durationFields;
    NSMutableArray<UITextField*> *distanceFields;
    NSMutableArray<UILabel*> *paceLbls;
    NSMutableArray<UILabel*> *backgroundLbls;
    int previousWidth;
    int scrollViewHeight;
    UIButton *addRunButton;
    LARRun *theRun;
    
    UILabel *distanceHeaderLbl;
    UILabel *durationHeaderLbl;
    UILabel *paceHeaderLbl;
}

@end

@implementation MultipleRunsViewController

-(void)setRun:(LARRun *)newRun {
    NSLog(@"setrun called");
    theRun = newRun;
    //if no run is posted yet, get workout from healthkit
    if ([theRun.distances[0] isEqualToString:@"0.00"] && (self.healthStore) && [theRun.distances count] == 1) {
        // the following dates cover the 24 hour period of the current day
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDate *now = _runDate;
        NSDateComponents *components = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:now];
        NSDate *startDate = [calendar dateFromComponents:components];
        NSDate *endDate = [calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:startDate options:0];
        HKSampleType *sampleType = [HKSampleType workoutType];
        NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionNone];
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:HKWorkoutSortIdentifierTotalDistance ascending:NO];
        NSLog(@"searching healthkit for runs");
        HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:sampleType predicate:predicate limit:HKObjectQueryNoLimit sortDescriptors:@[sortDescriptor] resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error) {
            if ([results count] > 0) {
                NSMutableArray *tempDistances = [[NSMutableArray alloc] init];
                NSMutableArray *tempDurations = [[NSMutableArray alloc] init];
                for (int i = 0; i < [results count]; i++) {
                    double miles = [((HKWorkout*)results[i]).totalDistance doubleValueForUnit:[HKUnit mileUnit]];
                    [tempDistances addObject:[NSString stringWithFormat:@"%.2lf",miles]];
                    [tempDurations addObject:[self stringFromTimeInterval:((HKWorkout*)results[i]).duration]];
                }
                NSLog(@"found runs");
                theRun.distances = tempDistances;
                theRun.durations = tempDurations;
            }
        }];
        [self.healthStore executeQuery:query];
    }
}

-(void)viewDidAppear:(BOOL)animated {
    
}

-(void)viewWillLayoutSubviews {
    if (previousWidth != self.navigationController.navigationBar.frame.size.width) {
        previousWidth = self.navigationController.navigationBar.frame.size.width;
        distanceHeaderLbl.frame = CGRectMake(0, 0, previousWidth / 3, 30);
        durationHeaderLbl.frame = CGRectMake(previousWidth / 3, 0, previousWidth / 3, 30);
        paceHeaderLbl.frame = CGRectMake(previousWidth * 2 / 3, 0, previousWidth / 3, 30);
        
        [backgroundLbls enumerateObjectsUsingBlock:^(UILabel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            CGRect frame = obj.frame;
            frame.size.width = previousWidth;
            obj.frame = frame;
        }];
        
        [distanceFields enumerateObjectsUsingBlock:^(UITextField * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            CGRect frame = obj.frame;
            frame.origin.x = 4;
            frame.size.width = previousWidth / 3 - 4;
            obj.frame = frame;
        }];
        
        [durationFields enumerateObjectsUsingBlock:^(UITextField * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            CGRect frame = obj.frame;
            frame.origin.x = previousWidth / 3 + 4;
            frame.size.width = previousWidth / 3 - 4;
            obj.frame = frame;
        }];
        
        [paceLbls enumerateObjectsUsingBlock:^(UILabel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            CGRect frame = obj.frame;
            frame.origin.x = previousWidth * 2 / 3;
            frame.size.width = previousWidth / 3;
            obj.frame = frame;
        }];
        
        CGRect frame = addRunButton.frame;
        frame.size.width = previousWidth;
        addRunButton.frame = frame;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"multiple run view did load");
    distanceFields = [[NSMutableArray alloc] init];
    durationFields = [[NSMutableArray alloc] init];
    paceLbls = [[NSMutableArray alloc] init];
    backgroundLbls = [[NSMutableArray alloc] init];
    
    double heightOffset = self.navigationController.navigationBar.frame.size.height + self.navigationController.navigationBar.frame.origin.y;
    previousWidth = self.navigationController.navigationBar.frame.size.width;
    
    if (self.view.frame.size.height == 480) {
        // resize things for 4s
        scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, heightOffset, previousWidth, 165)];
    } else {
        scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, heightOffset, previousWidth, 216)];
    }
    [self.view addSubview:scrollView];
    
    distanceHeaderLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, previousWidth / 3, 30)];
    distanceHeaderLbl.textAlignment = NSTextAlignmentCenter;
    distanceHeaderLbl.font  =[UIFont systemFontOfSize:20];
    distanceHeaderLbl.text = @"Distance";
    
    durationHeaderLbl = [[UILabel alloc] initWithFrame:CGRectMake(previousWidth / 3, 0, previousWidth / 3, 30)];
    durationHeaderLbl.textAlignment = NSTextAlignmentCenter;
    durationHeaderLbl.font  =[UIFont systemFontOfSize:20];
    durationHeaderLbl.text = @"Duration";
    
    paceHeaderLbl = [[UILabel alloc] initWithFrame:CGRectMake(previousWidth * 2 / 3, 0, previousWidth / 3, 30)];
    paceHeaderLbl.textAlignment = NSTextAlignmentCenter;
    paceHeaderLbl.font  =[UIFont systemFontOfSize:20];
    paceHeaderLbl.text = @"Pace";
    
    [scrollView addSubview:distanceHeaderLbl];
    [scrollView addSubview:durationHeaderLbl];
    [scrollView addSubview:paceHeaderLbl];
    
    scrollViewHeight = 30;
    
    addRunButton = [[UIButton alloc] initWithFrame:CGRectMake(0, scrollViewHeight, previousWidth, 25)];
    [addRunButton setTitle:@"Add Run" forState:UIControlStateNormal];
    [addRunButton setTitleColor:self.view.tintColor forState:UIControlStateNormal];
    addRunButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    [addRunButton addTarget:self action:@selector(addRun) forControlEvents:UIControlEventTouchUpInside];
    [scrollView addSubview:addRunButton];
    
    //if no run is posted yet, get workout from healthkit
    if ([theRun.distances[0] isEqualToString:@"0.00"] && (self.healthStore) && [theRun.distances count] == 1) {
        // the following dates cover the 24 hour period of the current day
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDate *now = _runDate;
        NSDateComponents *components = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:now];
        NSDate *startDate = [calendar dateFromComponents:components];
        NSDate *endDate = [calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:startDate options:0];
        HKSampleType *sampleType = [HKSampleType workoutType];
        NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionNone];
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:HKWorkoutSortIdentifierTotalDistance ascending:NO];
        HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:sampleType predicate:predicate limit:HKObjectQueryNoLimit sortDescriptors:@[sortDescriptor] resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([results count] > 0) {
                    NSMutableArray *tempDistances = [[NSMutableArray alloc] init];
                    NSMutableArray *tempDurations = [[NSMutableArray alloc] init];
                    for (int i = 0; i < [results count]; i++) {
                        double miles = [((HKWorkout*)results[i]).totalDistance doubleValueForUnit:[HKUnit mileUnit]];
                        [tempDistances addObject:[NSString stringWithFormat:@"%.2lf",miles]];
                        [tempDurations addObject:[self stringFromTimeInterval:((HKWorkout*)results[i]).duration]];
                    }
                    theRun.distances = tempDistances;
                    theRun.durations = tempDurations;
                }
                for (int i = 0; i < [theRun.distances count]; i++) {
                    [self addRun];
                }
            });
        }];
        [self.healthStore executeQuery:query];
    } else {
        for (int i = 0; i < [theRun.distances count]; i++) {
            [self addRun];
        }
    }
}

- (NSString *)stringFromTimeInterval:(NSTimeInterval)interval {
    NSInteger ti = (NSInteger)interval;
    NSInteger seconds = ti % 60;
    NSInteger minutes = (ti / 60) % 60;
    NSInteger hours = (ti / 3600);
    return [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)hours, (long)minutes, (long)seconds];
}

-(void)addRun {
    scrollViewHeight += 2;
    UILabel *backgroundLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, scrollViewHeight, previousWidth, 30)];
    backgroundLbl.backgroundColor = [UIColor colorWithRed:0.90 green:0.93 blue:0.78 alpha:1.0];
    [scrollView addSubview:backgroundLbl];
    [backgroundLbls addObject:backgroundLbl];
    
    UITextField *distanceField = [[UITextField alloc] initWithFrame:CGRectMake(4, scrollViewHeight + 1, previousWidth / 3 - 4, 28)];
    distanceField.borderStyle = UITextBorderStyleRoundedRect;
    distanceField.keyboardType = UIKeyboardTypeDecimalPad;
    distanceField.delegate = self;
    if ([distanceFields count] < [theRun.distances count]) {
        distanceField.text = theRun.distances[[distanceFields count]];
    } else {
        distanceField.text = @"0.00";
    }
    [distanceFields addObject:distanceField];
    [scrollView addSubview:distanceField];
    
    UITextField *durationField = [[UITextField alloc] initWithFrame:CGRectMake(previousWidth / 3 + 4, scrollViewHeight + 1, previousWidth / 3 - 4, 28)];
    durationField.borderStyle = UITextBorderStyleRoundedRect;
    durationField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    durationField.delegate = self;
    if ([durationFields count] < [theRun.durations count]) {
        durationField.text = theRun.durations[[durationFields count]];
    } else {
        durationField.text = @"00:00:00";
    }
    [durationFields addObject:durationField];
    [scrollView addSubview:durationField];
    
    UILabel *paceLbl = [[UILabel alloc] initWithFrame:CGRectMake(previousWidth * 2 / 3, scrollViewHeight, previousWidth / 3, 30)];
    paceLbl.textAlignment = NSTextAlignmentCenter;
    [scrollView addSubview:paceLbl];
    [paceLbls addObject:paceLbl];
    
    [self updatePaceLblForTextField:distanceField withNewString:distanceField.text];
    
    scrollViewHeight += 30;
    
    addRunButton.frame = CGRectMake(0, scrollViewHeight, previousWidth, 25);
    
    [scrollView setContentSize:CGSizeMake(previousWidth, scrollViewHeight + 25)];
}

-(void)updatePaceLblForTextField:(UITextField*)textField withNewString:(NSString*)string {
    NSUInteger index = [distanceFields indexOfObject:textField];
    double distance;
    NSArray *durationComponents;
    if (index == NSNotFound) {
        index = [durationFields indexOfObject:textField];
        distance = [distanceFields[index].text doubleValue];
        durationComponents = [string componentsSeparatedByString:@":"];
    } else {
        distance = [string doubleValue];
        durationComponents = [durationFields[index].text componentsSeparatedByString:@":"];
    }
    
    if ([durationComponents count] == 3 && distance != 0) {
        long seconds;
        @try {
            seconds = [durationComponents[2] integerValue] + [durationComponents[1] integerValue] * 60 + [durationComponents[0] integerValue] * 3600;
        } @catch (NSException *exception) {
            seconds = 0;
        } @finally {
            int pace = floor(seconds / distance);
            int minutes = floor(pace / 60);
            pace = pace % 60;
            int hours = floor(minutes / 60);
            minutes = minutes % 60;
            ((UILabel*)paceLbls[index]).text = [NSString stringWithFormat:@"%02d:%02d:%02d",hours,minutes,pace];
        }
    } else if ([durationComponents count] == 2 && distance != 0) {
        long seconds;
        @try {
            seconds = [durationComponents[1] integerValue] + [durationComponents[0] integerValue] * 60;
        } @catch (NSException *exception) {
            seconds = 0;
        } @finally {
            int pace = floor(seconds / distance);
            int minutes = floor(pace / 60);
            pace = pace % 60;
            int hours = floor(minutes / 60);
            minutes = minutes % 60;
            ((UILabel*)paceLbls[index]).text = [NSString stringWithFormat:@"%02d:%02d:%02d",hours,minutes,pace];
        }
    }
    
}

-(void)textFieldDidBeginEditing:(UITextField *)textField {
    if ([textField.text isEqualToString:@"0.00"] || [textField.text isEqualToString:@"00:00:00"]) {
        textField.text = @"";
    }
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    string = [textField.text stringByReplacingCharactersInRange:range withString:string];
    [self updatePaceLblForTextField:textField withNewString:string];
    return true;
}

-(void)updateArrProperties {
    if (scrollView) {
        // page view was loaded
        NSMutableArray *tempDistancesArr = [[NSMutableArray alloc] init];
        [distanceFields enumerateObjectsUsingBlock:^(UITextField * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [tempDistancesArr addObject:obj.text];
        }];
        self.distances = tempDistancesArr;
        
        NSMutableArray *tempDurationsArr = [[NSMutableArray alloc] init];
        [durationFields enumerateObjectsUsingBlock:^(UITextField * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [tempDurationsArr addObject:obj.text];
        }];
        self.durations = tempDurationsArr;
    } else {
        // view was never loaded, fill arrays with values from theRun
        NSLog(@"runs:%@",theRun.distances);
        self.distances = [NSMutableArray arrayWithArray:theRun.distances];
        self.durations = [NSMutableArray arrayWithArray:theRun.durations];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
