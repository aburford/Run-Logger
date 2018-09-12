//
//  EditView2Controller.m
//  Logarun
//
//  Created by Andrew Burford on 5/25/16.
//  Copyright © 2016 Andrew Burford. All rights reserved.
//

#import "EditView2Controller.h"

@implementation EditView2Controller {
    
    __weak IBOutlet NSLayoutConstraint *shoesHeight;
    __weak IBOutlet NSLayoutConstraint *shoesContainerHeight;
}

-(void)viewWillAppear:(BOOL)animated {
    [_weightField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0];
}

-(void)viewDidLoad {
    [super viewDidLoad];
    _morningPulseLabel.text = @"Morning\nPulse:";
    _sleepHoursLabel.text = @"Sleep\nHours:";
    TabBarController *theController = (TabBarController*)self.tabBarController;
    // check if user wants their health info added
    NSUserDefaults *defaults = [[NSUserDefaults standardUserDefaults] init];
    BOOL autoAddHealthData = [defaults boolForKey:@"phone-health"];
    if (autoAddHealthData) {
        NSLog(@"will attempt to add health data");
    } else {
        NSLog(@"user says not to add health data");
    }
    if ([_theRun.weight isEqualToString:@"0.00"] && (theController.healthStore) && autoAddHealthData) {
        // query for most recent weight
        NSDate *endDate = [_runDate dateByAddingTimeInterval:60*60*24];
        NSDate *startDate = [NSDate distantPast];
        HKSampleType *sampleType = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
        NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionNone];
        HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:sampleType predicate:predicate limit:HKObjectQueryNoLimit sortDescriptors:nil resultsHandler:^(HKSampleQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable results, NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"found weight data");
                _weightField.text = [NSString stringWithFormat:@"%.2lf",[((HKQuantitySample*)results.lastObject).quantity doubleValueForUnit:[HKUnit poundUnit]]];
            });
        }];
        [theController.healthStore executeQuery:query];
    } else {
        _weightField.text = _theRun.weight;
    }
    _sleepHoursField.text = _theRun.sleepHours;
    _morningPulseField.text = _theRun.morningPulse;
    _averageHRField.text = _theRun.averageHeartRate;
    if ([_theRun.percentBodyFat isEqualToString:@"0.00"] && (theController.healthStore) && autoAddHealthData) {
        // query for most recent body fat percentage
        NSDate *endDate = [_runDate dateByAddingTimeInterval:60*60*24];
        NSDate *startDate = [NSDate distantPast];
        HKSampleType *sampleType = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyFatPercentage];
        NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionNone];
        HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:sampleType predicate:predicate limit:HKObjectQueryNoLimit sortDescriptors:nil resultsHandler:^(HKSampleQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable results, NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"found body fat percentage data");
                _percentBodyFatField.text = [NSString stringWithFormat:@"%.2lf",[((HKQuantitySample*)results.firstObject).quantity doubleValueForUnit:[HKUnit percentUnit]] * 100];
            });
        }];
        [theController.healthStore executeQuery:query];
    } else {
        _percentBodyFatField.text = _theRun.percentBodyFat;
    }
    if (self.view.frame.size.height == 480) {
        // resize things for 4s
        shoesContainerHeight.constant = 84;
        shoesHeight.constant = 80;
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"TableEmbedSegue"]) {
        _theTableController = segue.destinationViewController;
        _theTableController.shoeKeyProperty = _theRun.shoeKey;
    }
}

-(void)textFieldDidBeginEditing:(UITextField *)textField {
    if ([textField.text isEqualToString:@"0.00"] || [textField.text isEqualToString:@"0.0"] ||  [textField.text isEqualToString:@"0"]) {
        textField.text = @"";
    }
}

@end
