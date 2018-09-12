//
//  LARInitialController.m
//  Logarun
//
//  Created by Andrew Burford on 5/28/16.
//  Copyright © 2016 Andrew Burford. All rights reserved.
//

#import "LARInitialController.h"

@implementation LARInitialController {
    LARSession *theSession;
    NSString *backupCookie;
    NSString *backupUsername;
}

-(void)viewDidLoad {
    [super viewDidLoad];
    
    // check if user defaults have been set yet
    NSUserDefaults *defaults = [[NSUserDefaults standardUserDefaults] init];
    if (![defaults objectForKey:@"phone-health"]) {
        // user defaults have not been set up yet, set them up now
        NSArray *presetTitlesArr = @[@"Blue Trails",@"Workout", @"Run at home",@"Meet Prep", @"Meet Day"];
        NSArray *presetNotesArr = @[@"Easy run today", @"I felt okay today",@"I felt a little tired today", @"Excited for the race tomorrow", @"I had a good race"];
        [defaults setBool:1 forKey:@"phone-health"];
        [defaults setBool:1 forKey:@"watch-health"];
        [defaults setBool:0 forKey:@"didFetchForYesterday"];
        [defaults setDouble:50.0 forKey:@"mileage-goal"];
        [defaults setObject:presetTitlesArr forKey:@"titles"];
        [defaults setObject:presetNotesArr forKey:@"notes"];
        [defaults setBool:YES forKey:@"newUser"];
    } else {
        NSLog(@"user defaults already set up");
    }
    
    //check if keychain exists
    NSMutableDictionary *passwordQueryDictionary = [[NSMutableDictionary alloc] init];
    [passwordQueryDictionary setObject:(__bridge id)kSecClassInternetPassword forKey:(__bridge id)kSecClass];
    [passwordQueryDictionary setObject:@"sqlAuthCookie" forKey:(__bridge id)kSecAttrLabel];
    [passwordQueryDictionary setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
    [passwordQueryDictionary setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
    
    // Then call Keychain Services to get the password:
    CFDataRef passwordData = NULL;
    OSStatus keychainError = noErr;
    keychainError = SecItemCopyMatching((__bridge CFDictionaryRef)passwordQueryDictionary,
                                        (CFTypeRef *)&passwordData);
    if (keychainError == noErr)
    {
        // Convert the password to an NSString:
        NSString *sqlAuthCookie = [[NSString alloc] initWithBytes:[(__bridge_transfer NSData *)passwordData bytes]
                                                      length:[(__bridge NSData *)passwordData length] encoding:NSUTF8StringEncoding];
        
        NSMutableDictionary *passwordQueryDictionary = [[NSMutableDictionary alloc] init];
        [passwordQueryDictionary setObject:(__bridge id)kSecClassInternetPassword forKey:(__bridge id)kSecClass];
        [passwordQueryDictionary setObject:@"sqlAuthCookie" forKey:(__bridge id)kSecAttrLabel];
        [passwordQueryDictionary setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnAttributes];
        [passwordQueryDictionary setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
        
        // Then call Keychain Services to get the username:
        CFDictionaryRef keychainAttrDictionary = NULL;
        OSStatus keychainError = noErr;
        keychainError = SecItemCopyMatching((__bridge CFDictionaryRef)passwordQueryDictionary,
                                            (CFTypeRef *)&keychainAttrDictionary);
        if (keychainError == noErr)
        {
            NSLog(@"keychain found");
            theSession = [[LARSession alloc] init];
            backupUsername = CFDictionaryGetValue(keychainAttrDictionary, @"acct");
            backupCookie = sqlAuthCookie;
            // request authorization just in case user deleted app and health data, but redownloaded with keychain still intact
            if ([HKHealthStore isHealthDataAvailable]) {
                NSSet *readTypes = [NSSet setWithObjects:[HKObjectType workoutType],[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass],[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyFatPercentage], nil];
                HKHealthStore *healthStore = [[HKHealthStore alloc] init];
                [healthStore requestAuthorizationToShareTypes:nil readTypes:readTypes completion:^(BOOL success, NSError * _Nullable error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        //Code that presents or dismisses a view controller here
                        NSLog(@"health access is configured");
                        [theSession loginWithUsername:CFDictionaryGetValue(keychainAttrDictionary, @"acct") sqlAuth:sqlAuthCookie delegate:self];
                        
                    });
                }];
            } else {
                [theSession loginWithUsername:CFDictionaryGetValue(keychainAttrDictionary, @"acct") sqlAuth:sqlAuthCookie delegate:self];
            }
        }

    }
    // go to login view if keychain item is not found
    else if (keychainError == errSecItemNotFound) {
        NSLog(@"no keychain found, going to login view");
        dispatch_async(dispatch_get_main_queue(), ^{
            [self performSegueWithIdentifier:@"toLoginView" sender:self];
        });
    }
}

-(void)sqlAuthIdDeleted {
    // tell the user that they must log in again and segue to log in
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Login Error"
                                                                   message:@"You must re-enter your username and password to continue. This error should occur no more than once a year."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* retryAction = [UIAlertAction actionWithTitle:@"Continue" style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction * action) {
                                                            [self performSegueWithIdentifier:@"toLoginView" sender:self];
                                                        }];
    [alert addAction:retryAction];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:alert animated:YES completion:nil];
    });
}

-(void)sessionDidLogin:(bool)success {
    if (success) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self performSegueWithIdentifier:@"toHome" sender:self];
        });
    } else {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Connection Error"
                                                                       message:@"Unable to connect to LogARun servers. Please check your network connection."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* retryAction = [UIAlertAction actionWithTitle:@"Retry" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                              [theSession loginWithUsername:backupUsername sqlAuth:backupCookie delegate:self];
                                                              }];
        [alert addAction:retryAction];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self presentViewController:alert animated:YES completion:nil];
        });
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"toHome"]) {
        TabBarController *theController = (TabBarController*)segue.destinationViewController;
        [theController setLARSession:theSession];
        if ([HKHealthStore isHealthDataAvailable]) {
            theController.healthStore = [[HKHealthStore alloc] init];
        }
    }
}


@end
