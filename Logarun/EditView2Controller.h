//
//  EditView2Controller.h
//  Logarun
//
//  Created by Andrew Burford on 5/25/16.
//  Copyright © 2016 Andrew Burford. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LARRun.h"
#import "EditViewProtocol.h"
#import "ShoeTableController.h"
#import "TabBarController.h"

@interface EditView2Controller : UIViewController <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *weightField;
@property (weak, nonatomic) IBOutlet UITextField *sleepHoursField;
@property (weak, nonatomic) IBOutlet UITextField *morningPulseField;
@property (weak, nonatomic) IBOutlet UITextField *averageHRField;
@property (weak, nonatomic) IBOutlet UITextField *percentBodyFatField;
@property (weak, nonatomic) IBOutlet UILabel *morningPulseLabel;
@property (weak, nonatomic) IBOutlet UILabel *sleepHoursLabel;

@property (nonatomic) NSDate *runDate;
@property (nonatomic, strong) LARRun *theRun;
@property (nonatomic) ShoeTableController *theTableController;

@end
