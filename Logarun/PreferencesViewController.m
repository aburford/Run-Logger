//
//  PreferencesViewController.m
//  Run Logger
//
//  Created by Andrew Burford on 10/2/16.
//  Copyright © 2016 Andrew Burford. All rights reserved.
//

#import "PreferencesViewController.h"

@interface PreferencesViewController () {
    __weak IBOutlet UIPickerView *readPickerView;
    __weak IBOutlet UIPickerView *writePickerView;
    __weak IBOutlet UIPickerView *weekDayPickerView;
    __weak IBOutlet UIActivityIndicatorView *activityIndicator;
}

@end

@implementation PreferencesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    TabBarController *theController = (TabBarController*)self.tabBarController;
    LARSession *theSession = theController.theSession;
    [theSession getCommentsPermissionsToDelegate:self];
    [[self.view subviews] enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.class != [UIActivityIndicatorView class]) {
            [obj setHidden:1];
        }
    }];
}

-(void)didReceiveCommentViewPermissions:(CommentPermission)viewPermission writePermissions:(CommentPermission)writePermission {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self.view subviews] enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.class != [UIActivityIndicatorView class]) {
                [obj setHidden:0];
            } else {
                [(UIActivityIndicatorView*)obj stopAnimating];
            }
        }];
        [readPickerView selectRow:viewPermission inComponent:0 animated:YES];
        [writePickerView selectRow:writePermission inComponent:0 animated:YES];
        NSUserDefaults *defaults = [[NSUserDefaults standardUserDefaults] init];
        if ([[defaults objectForKey:@"firstDayOfWeek"] isEqualToString:@"1"]) {
            // make adjustment because first day of week is monday
            [weekDayPickerView selectRow:1 inComponent:0 animated:YES];
        }
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)savePressed:(id)sender {
    UIActivityIndicatorView *barActivityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    barActivityIndicator.frame = CGRectMake(0, 0, 20, 20);
    UIBarButtonItem *activity = [[UIBarButtonItem alloc] initWithCustomView:barActivityIndicator];
    [[self navigationItem] setRightBarButtonItem:activity];
    [barActivityIndicator startAnimating];
    
    TabBarController *theController = (TabBarController*)self.tabBarController;
    LARSession *theSession = theController.theSession;
    [theSession postCommentReadPermission:(int)[readPickerView selectedRowInComponent:0]writePermission:(int)[writePickerView selectedRowInComponent:0] dayOfWeek:(int)[weekDayPickerView selectedRowInComponent:0] delegate:self];
}

#pragma mark - UIPickerView Stuff

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if ([pickerView isEqual:weekDayPickerView]) {
        return 2;
    } else if ([pickerView isEqual:readPickerView]) {
        return 6;
    } else if ([pickerView isEqual:writePickerView]) {
        return 6;
    } else {
        return 0;
    }
}

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

-(void)preferencesUpdated:(BOOL)success {
    if (success) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.navigationController popViewControllerAnimated:YES];
        });
    } else {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Connection Error"
                                                                       message:@"Unable to connect to LogARun servers. Please check your network connection."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  [self.navigationController popViewControllerAnimated:YES];
                                                              }];
        [alert addAction:defaultAction];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self presentViewController:alert animated:YES completion:nil];
        });
    }
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if ([pickerView isEqual:weekDayPickerView]) {
        switch (row) {
            case 0:
                return @"Sunday";
            case 1:
                return @"Monday";
            default:
                return @"";
                break;
        }
    } else {
        switch (row) {
            case 0:
                return @"Default";
            case 1:
                return @"No one";
            case 2:
                return @"Coaches";
            case 3:
                return @"Team mates";
            case 4:
                return @"All users";
            case 5:
                return @"Everyone";
            default:
                return @"";
        }
    }
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
