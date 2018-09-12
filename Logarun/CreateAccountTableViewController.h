//
//  CreateAccountTableViewController.h
//  Run Logger
//
//  Created by Andrew Burford on 9/14/16.
//  Copyright © 2016 Andrew Burford. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ViewController.h"
#import "LARSession.h"
@class ViewController;

@interface CreateAccountTableViewController : UITableViewController <UIPickerViewDataSource, UIPickerViewDelegate, LARSessionDelegateProtocol>

@property (weak,nonatomic) ViewController *delegate;
@property (weak,nonatomic) LARSession *theLARSession;

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component;
-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView;
-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component;
-(void)accountCreationReceivedResponse:(CreationStatus)status;

@end
