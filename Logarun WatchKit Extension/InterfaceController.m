//
//  InterfaceController.m
//  Logarun WatchKit Extension
//
//  Created by Andrew Burford on 4/27/16.
//  Copyright © 2016 Andrew Burford. All rights reserved.
//

#import "InterfaceController.h"
#import "LARWatchSession.h"

@interface InterfaceController()

@end


@implementation InterfaceController {
    LARWatchSession *theSession;
    NSString *milesRan;
    NSString *duration;
    NSString *durationHours;
    NSString *durationMinutes;
    NSString *durationSeconds;
    NSString *dayTitleString;
    NSString *dailyNoteString;
    
    NSMutableDictionary *pendingChange;
    NSString *pendingNumber;
    
    HKHealthStore *healthStore;
    NSString *percentBodyFat;
    NSString *weight;
}

- (IBAction)postButtonPressed {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM-dd-yyyy"];
    NSDate *today = [NSDate date];
    NSString *formattedDateString = [dateFormatter stringFromDate:today];
    
    // debug
    // formattedDateString = @"3/14/2016";
    
    duration = [NSString stringWithFormat:@"%@:%@:%@",durationHours,durationMinutes,durationSeconds];
    
    NSUserDefaults *defaults = [[NSUserDefaults standardUserDefaults] init];
    BOOL submitData = [[defaults objectForKey:@"submit-data"] boolValue];
    NSLog(@"submit health data: %d",submitData);
    if (healthStore && submitData) {
        NSLog(@"health data available for weight/body fat %%");
        // get weight and body fat percentage
        BOOL __block waitForWeight = true;
        BOOL __block waitForFat = true;
        
        // query for most recent body mass
        NSDate *now = [NSDate date];
        NSDate *endDate = [now dateByAddingTimeInterval:60*60*24];
        NSDate *startDate = [NSDate distantPast];
        HKSampleType *sampleType = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
        NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionNone];
        HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:sampleType predicate:predicate limit:HKObjectQueryNoLimit sortDescriptors:nil resultsHandler:^(HKSampleQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable results, NSError * _Nullable error) {
            
            waitForWeight = false;
            weight = [NSString stringWithFormat:@"%.2lf",[((HKQuantitySample*)results.lastObject).quantity doubleValueForUnit:[HKUnit poundUnit]]];
            NSLog(@"weight was found: %@",weight);
            if (!waitForFat) {
                [theSession postRunOnDate:formattedDateString dayTitle:dayTitleString distance:milesRan duration:duration dailyNote:dailyNoteString weight:weight percentBodyFat:percentBodyFat];
                [self popController];
                NSLog(@"run is being posted");
            }
        }];
        [healthStore executeQuery:query];
        
        // query for most recent percent body fat
        HKSampleType *sampleType2 = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyFatPercentage];
        NSPredicate *predicate2 = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionNone];
        HKSampleQuery *query2 = [[HKSampleQuery alloc] initWithSampleType:sampleType2 predicate:predicate2 limit:HKObjectQueryNoLimit sortDescriptors:nil resultsHandler:^(HKSampleQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable results, NSError * _Nullable error) {
            waitForFat = false;
            percentBodyFat = [NSString stringWithFormat:@"%.2lf",[((HKQuantitySample*)results.firstObject).quantity doubleValueForUnit:[HKUnit percentUnit]] * 100];
            NSLog(@"percent body fat was found: %@",percentBodyFat);
            if (!waitForWeight) {
                [theSession postRunOnDate:formattedDateString dayTitle:dayTitleString distance:milesRan duration:duration dailyNote:dailyNoteString weight:weight percentBodyFat:percentBodyFat];
                [self popController];
                NSLog(@"run is being posted");
            }
        }];
        [healthStore executeQuery:query2];
        /*
        if (!waitForFat && !waitForWeight) {
            [theSession postRunOnDate:formattedDateString dayTitle:dayTitleString distance:milesRan duration:duration dailyNote:dailyNoteString weight:@"0.00" percentBodyFat:@"0.00"];
            [self popController];
            NSLog(@"run was posted");
        }
         */
    } else {
        NSLog(@"health data not available for weight/body fat %% or user turned off automatic submission of health data");
        [theSession postRunOnDate:formattedDateString dayTitle:dayTitleString distance:milesRan duration:duration dailyNote:dailyNoteString weight:@"0.00" percentBodyFat:@"0.00"];
        [self popController];
    }
}

- (IBAction)hoursChanged:(NSInteger)value {
    durationHours = [NSString stringWithFormat:@"%d",value];
}
- (IBAction)minutesChanged:(NSInteger)value {
    durationMinutes = [NSString stringWithFormat:@"%d",value];
}
- (IBAction)secondsChanged:(NSInteger)value {
    durationSeconds = [NSString stringWithFormat:@"%d",value];
}

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    theSession = context[0];
    // get workout values
    if ([HKHealthStore isHealthDataAvailable]) {
        healthStore = [[HKHealthStore alloc] init];
    }
    if (healthStore) {
        NSLog(@"health data is available");
            NSSet *readTypes = [NSSet setWithObjects:[HKObjectType workoutType],[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass],[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyFatPercentage], nil];
            healthStore = [[HKHealthStore alloc] init];
            [healthStore requestAuthorizationToShareTypes:nil readTypes:readTypes completion:^(BOOL success, NSError * _Nullable error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    //Code that presents or dismisses a view controller here
                    NSLog(@"request success: %d",success);
                });
            }];
        
        // the following dates cover the 24 hour period of the current day
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDate *now = [NSDate date];
        NSDateComponents *components = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:now];
        NSDate *startDate = [calendar dateFromComponents:components];
        NSDate *endDate = [calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:startDate options:0];
        HKSampleType *sampleType = [HKSampleType workoutType];
        NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionNone];
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:HKWorkoutSortIdentifierTotalDistance ascending:NO];
        NSLog(@"executing query for workout");
        HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:sampleType predicate:predicate limit:HKObjectQueryNoLimit sortDescriptors:@[sortDescriptor] resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error) {
            NSLog(@"query done: %@",results);
            dispatch_async(dispatch_get_main_queue(), ^{
                double miles = [((HKWorkout*)results.firstObject).totalDistance doubleValueForUnit:[HKUnit mileUnit]];
                milesRan = [NSString stringWithFormat:@"%.2lf",miles];
                [_mileageLabel setText:milesRan];
                NSInteger ti = (NSInteger)(((HKWorkout*)results.firstObject).duration);
                durationSeconds = [NSString stringWithFormat:@"%02ld",(long)(ti % 60)];
                [_secondsPicker setSelectedItemIndex:(ti % 60)];
                durationMinutes = [NSString stringWithFormat:@"%02ld",(long)((ti / 60) % 60)];
                [_minutesPicker setSelectedItemIndex:((ti / 60) % 60)];
                durationHours = [NSString stringWithFormat:@"%02ld",(long)(ti / 3600)];
                [_hoursPicker setSelectedItemIndex:(ti / 3600)];
            });
        }];
        [healthStore executeQuery:query];
    } else {
        NSLog(@"health store was unavailable");
        durationHours = @"00";
        durationMinutes = @"00";
        durationSeconds = @"00";
        milesRan = @"0.00";
    }

    
    
    // MAKE EVERYTHING VISIBLE
    dayTitleString = @"";
    dailyNoteString = @"";
    
    
    [_mileageLabel setText:milesRan];
    NSMutableArray *sixtyItemsArray = [[NSMutableArray alloc]init];
    for (int i=0; i<60; i++) {
        WKPickerItem *theItem = [[WKPickerItem alloc]init];
        theItem.title = [NSString stringWithFormat:@"%d",i];
        theItem.caption = @"Hours";
        [sixtyItemsArray addObject:theItem];
    }
    [_hoursPicker setItems:sixtyItemsArray];
    for (WKPickerItem *item in sixtyItemsArray){
        item.caption = @"Minutes";
    }
    [_minutesPicker setItems:sixtyItemsArray];
    for (WKPickerItem *item in sixtyItemsArray){
        item.caption = @"Seconds";
    }
    [_secondsPicker setItems:sixtyItemsArray];
    
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    
    if ([[pendingChange objectForKey:@"resultType"] isEqualToString:@"Day Title"] && pendingChange != nil) {
        dayTitleString = [pendingChange objectForKey:@"result"];
        [_dayTitleLbl setText:dayTitleString];
        if ([[pendingChange objectForKey:@"result"]isEqualToString:@""]) {
            [_dayTitleLbl setHidden:1];
        } else {
            [_dayTitleLbl setHidden:0];
        }
    } else if (pendingChange != nil) {
        dailyNoteString = [pendingChange objectForKey:@"result"];
        [_dailyNoteLbl setText:dailyNoteString];
        if ([[pendingChange objectForKey:@"result"]isEqualToString:@""]) {
            [_dailyNoteLbl setHidden:1];
        } else {
            [_dailyNoteLbl setHidden:0];
        }

    }
    pendingChange = nil;
    if (pendingNumber) {
        if ([pendingNumber isEqualToString:@""]) {
            pendingNumber = @"0.00";
        }
        milesRan = pendingNumber;
        [_mileageLabel setText:milesRan];
    }
    pendingNumber = nil;
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

- (IBAction)dayTitlePressed {
    NSArray *contextArray = [NSArray arrayWithObjects:self,@"Day Title", dayTitleString, nil];
    [self pushControllerWithName:@"inputTextView" context:contextArray];
}
- (IBAction)dailyNotePressed {
    NSArray *contextArray = [NSArray arrayWithObjects:self,@"Daily Note", dailyNoteString, nil];
    [self pushControllerWithName:@"inputTextView" context:contextArray];
}

- (IBAction)setMileagePressed {
    NSArray *contextArray = [NSArray arrayWithObjects:self,milesRan,nil];
    [self pushControllerWithName:@"editMileageView" context:contextArray];
}

-(void)newNumberReturned:(NSString *)numberStr {
    pendingNumber = numberStr;
}

-(void)newResultReturned:(NSMutableDictionary *)result {
    pendingChange = result;
}

@end



