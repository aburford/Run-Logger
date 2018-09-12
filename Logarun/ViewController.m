//
//  ViewController.m
//  Logarun
//
//  Created by Andrew Burford on 4/27/16.
//  Copyright © 2016 Andrew Burford. All rights reserved.
//

#import "ViewController.h"
#import "LARSession.h"
#import <Security/Security.h>
@import Security;

@interface ViewController ()

@end

@implementation ViewController {
    HKHealthStore *healthStore;
    BOOL loginPressed;
}

-(void)sessionDidLogin:(BOOL)success {
    if (success==1) {
        dispatch_async(dispatch_get_main_queue(), ^{

            [_activityIndicator stopAnimating];
        });
        
        // ask for health access
        if ([HKHealthStore isHealthDataAvailable]) {
            NSSet *readTypes = [NSSet setWithObjects:[HKObjectType workoutType],[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass],[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyFatPercentage], nil];
            healthStore = [[HKHealthStore alloc] init];
            [healthStore requestAuthorizationToShareTypes:nil readTypes:readTypes completion:^(BOOL success, NSError * _Nullable error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    // Code that presents or dismisses a view controller here
                    [self performSegueWithIdentifier:@"toHome" sender:self];
                });
            }];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                //Code that presents or dismisses a view controller here
                [self performSegueWithIdentifier:@"toHome" sender:self];
            });
        }
    } else {
        loginPressed = false;
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Authentication error. Please check your credentials and network connection." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil];
            [alertView show];
            [_activityIndicator stopAnimating];
        });
    }
}


-(void)viewWillAppear:(BOOL)animated {
    _passwordTextField.text = @"";
    [_usernameTextField becomeFirstResponder];
    loginPressed = false;
    
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == _usernameTextField) {
        [_passwordTextField becomeFirstResponder];
    } else if (textField == _passwordTextField) {
        [self loginButtonPressed:self];
    }
    return NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _usernameTextField.delegate = self;
    _passwordTextField.delegate = self;
    
    LARSession *newSession = [[LARSession alloc] init];
    _theSession = newSession;
    
    if (self.view.frame.size.height == 480) {
        [self.creditsLabel removeFromSuperview];
        [self.creditsLabel setHidden:YES];
        self.creditsLabel = nil;
        [self.createAccountButton removeConstraints:self.createAccountButton.constraints];
        [self.createAccountButton removeFromSuperview];
        self.createAccountButton = nil;
        [self.createAccountButton setHidden:1];
        self.createAccountButton = [[UIButton alloc] initWithFrame:CGRectMake(210, 221, 110, 38)];
        [self.createAccountButton setTitle:@"Create account" forState:UIControlStateNormal];
        self.createAccountButton.titleLabel.font = [UIFont systemFontOfSize:15.0];
        [self.createAccountButton setTitleColor:[UIColor colorWithRed:0 green:0.478431 blue:1 alpha:1] forState:normal];
        [self.createAccountButton addTarget:self action:@selector(createAccountPressed) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:self.createAccountButton];
        
        
        NSLog(@"%@",_activityIndicator.constraints);
        [self.activityIndicator removeConstraints:self.activityIndicator.constraints];
        [self.activityIndicator removeFromSuperview];
        self.activityIndicator = nil;
        
        self.activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(20, 221, 110, 38)];
        self.activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
        [self.view addSubview:self.activityIndicator];
    }
    
    // Do any additional setup after loading the view, typically from a nib.
}

-(void)createAccountPressed {
    [self performSegueWithIdentifier:@"toCreationTable" sender:self];
}

- (IBAction)loginButtonPressed:(id)sender {
    if (!loginPressed) {
        [_theSession loginWithUsername:_usernameTextField.text password:_passwordTextField.text delegate:self];
        [_activityIndicator startAnimating];
    }
    loginPressed = true;
}



-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"toHome"]) {
        TabBarController *theController = (TabBarController*)segue.destinationViewController;
        [theController setLARSession:_theSession];
        if (healthStore) {
            theController.healthStore = healthStore;
        }
    } else if ([segue.identifier isEqualToString:@"toCreationTable"]) {
        ((CreateAccountTableViewController*)((UINavigationController*)segue.destinationViewController).viewControllers[0]).delegate = self;
        NSLog(@"view controller session:%@",self.theSession);
        ((CreateAccountTableViewController*)((UINavigationController*)segue.destinationViewController).viewControllers[0]).theLARSession = self.theSession;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
