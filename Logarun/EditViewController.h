//
//  EditViewController.h
//  Logarun
//
//  Created by Andrew Burford on 5/11/16.
//  Copyright © 2016 Andrew Burford. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LARRun.h"
#import "LARSession.h"
#import "TabBarController.h"
#import "EditViewProtocol.h"

@interface EditViewController : UIViewController <EditViewProtocol>

@property (nonatomic) NSDate *runDate;
@property (nonatomic) HKHealthStore *healthStore;
@property (weak, nonatomic) NSString *date;
@property (weak, nonatomic) IBOutlet UITextField *dayTitleField;
@property (weak, nonatomic) IBOutlet UITextView *dailyNoteView;
@property (nonatomic) NSUInteger* index;

-(void)setRun:(LARRun*)incomingRun;


@end
