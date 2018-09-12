//
//  ViewController.h
//  Logarun
//
//  Created by Andrew Burford on 4/27/16.
//  Copyright © 2016 Andrew Burford. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TabBarController.h"
#import "CreateAccountTableViewController.h"
@import Security;
@import SafariServices;

@class LARSession;

@interface ViewController : UIViewController <LARSessionDelegateProtocol, UITextFieldDelegate, SFSafariViewControllerDelegate>


@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (strong, atomic) IBOutlet UIButton *createAccountButton;
@property (weak, nonatomic) IBOutlet UILabel *creditsLabel;
@property (strong, nonatomic) LARSession *theSession;

-(BOOL)textFieldShouldReturn:(UITextField *)textField;
-(void)sessionDidLogin:(BOOL)success;
-(void)createAccountPressed;
- (IBAction)loginButtonPressed:(id)sender;

@end

