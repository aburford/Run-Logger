//
//  HomeViewController.m
//  Logarun
//
//  Created by Andrew Burford on 6/15/16.
//  Copyright © 2016 Andrew Burford. All rights reserved.
//

#import "HomeViewController.h"
@import CoreGraphics;

@implementation HomeViewController
{
    LARWatchSession *theSession;
    NSArray *allMainViewControls;
    double currentMileage;
    BOOL userAlreadyRan;
    BOOL currentlyVisible;
    BOOL pendingMileageRefresh;
}

- (IBAction)editRunPressed {
    NSArray *contextArray = [NSArray arrayWithObjects:theSession, nil];
    [self pushControllerWithName:@"editRunView" context:contextArray];
}

 
- (IBAction)refreshButtonPressed {
    [_refreshingLbl setHidden:NO];
    NSLog(@"getting current mileage because refresh was pressed");
    [theSession getCurrentMileage];
}

-(void)renderMileageRingAndRecommendationWithMileage:(double)weeklyMileage userAlreadyRan:(bool)alreadyRan {
    NSUserDefaults *defaults = [[NSUserDefaults standardUserDefaults] init];
    double goalDbl = [[defaults objectForKey:@"mileage-goal"] doubleValue];
    double leftDbl = goalDbl - currentMileage;
    
    // find days left in week
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"e"];
    int dayIndex = (int)[[dateFormatter stringFromDate:[NSDate date]] integerValue];
    if ([[defaults objectForKey:@"firstDayOfWeek"] isEqualToString:@"1"]) {
        // make adjustment because first day of week is monday
        switch (dayIndex) {
            case 1:
                dayIndex = 7;
                break;
            default:
                dayIndex -=1;
                break;
        }
    }
    int daysLeft = 8 - dayIndex;
    if (alreadyRan) {
        daysLeft--;
    }
    
    NSString *mileageString;
    if (leftDbl <= 0) {
        mileageString = @"Good job, you hit your mileage for the week!";
    } else {
        switch (daysLeft) {
            case 0:
                mileageString = [NSString stringWithFormat:@"You were %.2lf miles short this week",leftDbl];
                break;
            case 1:
                if (userAlreadyRan) {
                    mileageString = [NSString stringWithFormat:@"%.2lf more miles to run tomorrow",leftDbl];
                } else {
                    mileageString = [NSString stringWithFormat:@"%.2lf more miles to run today",leftDbl];
                }
                break;
            default:
                mileageString = [NSString stringWithFormat:@"%.2lf more miles\nRun %.2lf miles a day for the next %d days to hit your goal",leftDbl,leftDbl / (double)daysLeft,daysLeft];
                break;
        }
    }
    
    [_mileageLbl setText:mileageString];
    [_mileageLbl setHidden:NO];
    
    // create the arc image
    WKInterfaceDevice *current = [WKInterfaceDevice currentDevice];
    CGRect rect = current.screenBounds;
    int screenWidth = rect.size.width;
    
    CGFloat arcWidth = 18;
    
    // make it square and slightly smaller
    rect.size.width *= 2;
    rect.size.height = rect.size.width;
    
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, arcWidth);
    
    CGPoint centerPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
    
    CGFloat fullCircle = 2.0 * M_PI;
    CGFloat start = -0.25 * fullCircle;
    CGFloat end;
    if (currentMileage == 0) {
        end = start + 0.03;
    } else {
        end = currentMileage / goalDbl * fullCircle + start;
    }
    
    // add the background circle
    CGContextAddArc(context, centerPoint.x, centerPoint.y, (rect.size.width - arcWidth) / 2, 0, fullCircle, 0);
    CGContextSetStrokeColorWithColor(context, [UIColor colorWithRed:0.01 green:0.18 blue:0.02 alpha:1.0].CGColor);
    CGContextStrokePath(context);
    
    // add the arc
    CGContextAddArc(context, centerPoint.x, centerPoint.y, (rect.size.width - arcWidth) / 2, start, end, 0);
    CGContextSetStrokeColorWithColor(context, [UIColor colorWithRed:0.34 green:0.43 blue:0.22 alpha:1.0].CGColor);
    CGContextStrokePath(context);
    
    // add fraction line
    CGContextSetLineWidth(context, 1);
    CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextMoveToPoint (context, rect.size.width / 2 - 35, rect.size.height / 2);
    CGContextAddLineToPoint (context, rect.size.width / 2 + 35, rect.size.height / 2);
    CGContextStrokePath(context);
    
    // add mileage goal text
    UIFont *font = [UIFont monospacedDigitSystemFontOfSize:44 weight:UIFontWeightLight];
    
    NSMutableParagraphStyle *paragraphStyle = NSMutableParagraphStyle.new;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName,[UIColor whiteColor],NSForegroundColorAttributeName,paragraphStyle,NSParagraphStyleAttributeName, nil];
    [[NSString stringWithFormat:@"%.1lf",goalDbl] drawInRect:CGRectMake(0, rect.size.height / 2, rect.size.width, rect.size.height / 2) withAttributes:attributes];
    [[NSString stringWithFormat:@"%.1lf",currentMileage] drawInRect:CGRectMake(0, rect.size.height / 2 - 54, rect.size.width, rect.size.height / 2) withAttributes:attributes];
    
    UIImage *UIImgRing = [UIImage imageWithCGImage:CGBitmapContextCreateImage(context)];
    UIGraphicsEndImageContext();
    [_ringImage setImage:UIImgRing];
    [_ringImage setHeight:screenWidth - 22];
    [_ringImage setWidth:screenWidth - 22];
    [_ringImage setHidden:NO];
    
    [_refreshingLbl setHidden:YES];
}

-(void)didReceiveMileage:(double)weeklyMileage userAlreadyRan:(bool)alreadyRan{
    if (weeklyMileage != -1) {
        currentMileage = weeklyMileage;
        userAlreadyRan = alreadyRan;
        
        if (!currentlyVisible) {
            NSLog(@"mileage was received but view is not visible, will redo calculations when view is visible again");
            pendingMileageRefresh = true;
        } else {
            pendingMileageRefresh = false;
            [self renderMileageRingAndRecommendationWithMileage:weeklyMileage userAlreadyRan:alreadyRan];
        }
    } else {
        NSLog(@"mileage request failed");
        [self presentAlertControllerWithTitle:@"Connection Error" message:@"Unable to connect with the LogARun servers" preferredStyle:WKAlertControllerStyleAlert actions:@[[WKAlertAction actionWithTitle:@"Okay" style:WKAlertActionStyleDefault handler:^{
            NSLog(@"hiding refreshing label");
            [self.refreshingLbl performSelector:@selector(setHidden:) withObject:@YES afterDelay:0.1];
        }]]];
    }
}

-(void)hideRefreshingLabel {
    
    
}

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    
    pendingMileageRefresh = false;
    
    allMainViewControls = [NSArray arrayWithObjects:_mileageLbl,_refreshMileageButton,_firstSeparator,_editRunButton,_refreshingLbl,_graphTitleLbl,_ringImage, nil];
    
    // check if health default has been set yet
    NSUserDefaults *defaults = [[NSUserDefaults standardUserDefaults] init];
    if ([defaults objectForKey:@"submit-data"] == nil) {
        NSLog(@"health default has not been set yet, setting it to true");
        NSNumber *boolNumber = [NSNumber numberWithBool:1];
        [defaults setObject:boolNumber forKey:@"submit-data"];
    }
    if ([defaults objectForKey:@"mileage-goal"] == nil) {
        NSLog(@"mileage goal not set, setting to default of 50");
        [defaults setObject:@"50" forKey:@"mileage-goal"];
    }
    
    // init WCSession in case of new context
    if([WCSession isSupported]){
        self.watchSession = [WCSession defaultSession];
        self.watchSession.delegate = self;
        [self.watchSession activateSession];
    }
    
    //check if keychain exists by creating search dictionary
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
            NSLog(@"default shoe: %@",CFDictionaryGetValue(keychainAttrDictionary, (__bridge id)kSecAttrComment));
            NSLog(@"username: %@",CFDictionaryGetValue(keychainAttrDictionary, @"acct"));
            NSLog(@"sqlAuthCookie: %@",sqlAuthCookie);
            
            //login with LARSession and make everything visible
            LARWatchSession *watchLARSession = [[LARWatchSession alloc] init];
            [watchLARSession loginWithUsername:CFDictionaryGetValue(keychainAttrDictionary, @"acct") sqlAuth:sqlAuthCookie shoe:CFDictionaryGetValue(keychainAttrDictionary, (__bridge id)kSecAttrComment) delegate:self];
            theSession = watchLARSession;
            
            // MAKE EVERYTHING VISIBLE
            NSLog(@"getting current mileage because app just opened");
            [theSession getCurrentMileage];
            for (WKInterfaceObject* control in allMainViewControls) {
                [control setHidden:NO];
            }
            [_mileageLbl setHidden:YES];
            [_ringImage setHidden:YES];
            [_pleaseLoginLabel setHidden:YES];
            [self setTitle:CFDictionaryGetValue(keychainAttrDictionary, @"acct")];
        }
        
    }
    
    else if (keychainError == errSecItemNotFound) {
        NSLog(@"no keychain found");
        
        
        
        // KEEP EVERYTHING HIDDEN, USER HAS NOT LOGGED IN
        
        
        
    }
}

-(void)runPostFailed {
    [self presentAlertControllerWithTitle:@"Connection Error" message:@"Run could not be posted because Apple Watch is unable to connect with the LogARun servers" preferredStyle:WKAlertControllerStyleAlert actions:@[[WKAlertAction actionWithTitle:@"Okay" style:WKAlertActionStyleDefault handler:^{
    }]]];
}

-(void)session:(WCSession *)session activationDidCompleteWithState:(WCSessionActivationState)activationState error:(NSError *)error {
    
}

/** Called on the delegate of the receiver. Will be called on startup if an applicationContext is available. */
- (void) session:(WCSession *)session didReceiveApplicationContext:(NSDictionary<NSString *,id> *)applicationContext {
    NSLog(@"WCSession received new application context: %@",applicationContext);
    
    //check if context says to logout, or if it has a new keychain to log in with
    if ([[applicationContext objectForKey:@"logout"]  isEqual: @YES]) {
        NSLog(@"context says just to logout");
        // just logout
        // delete ALL previous keychains (just in case)
        OSStatus keychainError = noErr;
        do {
            NSMutableDictionary *passwordQueryDictionary = [[NSMutableDictionary alloc] init];
            [passwordQueryDictionary setObject:(__bridge id)kSecClassInternetPassword forKey:(__bridge id)kSecClass];
            [passwordQueryDictionary setObject:@"sqlAuthCookie" forKey:(__bridge id)kSecAttrLabel];
            //[passwordQueryDictionary setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
            //[passwordQueryDictionary setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
            
            SecItemDelete((__bridge CFDictionaryRef)passwordQueryDictionary);
            
            CFDictionaryRef tempDictionary = NULL;
            keychainError = SecItemCopyMatching((__bridge CFDictionaryRef)passwordQueryDictionary,
                                                (CFTypeRef *)&tempDictionary);
            
        } while (keychainError == noErr);
        
        
        // MAKE EVERYTHING HIDDEN
        for (WKInterfaceObject* control in allMainViewControls) {
            [control setHidden:YES];
        }
        [_pleaseLoginLabel setHidden:NO];
        [self setTitle:@"Logarun"];
        
    } else {
        // delete ALL previous keychains (just in case)
        NSLog(@"deleting previous keychain");
        OSStatus keychainError = noErr;
        do {
            NSMutableDictionary *passwordQueryDictionary = [[NSMutableDictionary alloc] init];
            [passwordQueryDictionary setObject:(__bridge id)kSecClassInternetPassword forKey:(__bridge id)kSecClass];
            [passwordQueryDictionary setObject:@"sqlAuthCookie" forKey:(__bridge id)kSecAttrLabel];
            //[passwordQueryDictionary setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
            //[passwordQueryDictionary setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
            
            SecItemDelete((__bridge CFDictionaryRef)passwordQueryDictionary);
            
            CFDictionaryRef tempDictionary = NULL;
            keychainError = SecItemCopyMatching((__bridge CFDictionaryRef)passwordQueryDictionary,
                                                (CFTypeRef *)&tempDictionary);
            
        } while (keychainError == noErr);
        //NSMutableDictionary *newAccountDictionary = [NSMutableDictionary dictionaryWithDictionary:applicationContext];
        
        //login with LARSession
        NSLog(@"LARSession is logging in with new credentials");
        LARWatchSession *watchLARSession = [[LARWatchSession alloc] init];
        NSString *sqlAuthCookieString = [[NSString alloc] initWithData:[applicationContext objectForKey:(__bridge id)kSecValueData] encoding:NSUTF8StringEncoding];
        [watchLARSession loginWithUsername:[applicationContext objectForKey:(__bridge id)kSecAttrAccount] sqlAuth:sqlAuthCookieString shoe:[applicationContext objectForKey:@"shoe"] delegate:self];
        theSession = watchLARSession;
        
        
        // MAKE EVERYTHING APPEAR
        
        for (WKInterfaceObject* control in allMainViewControls) {
            [control setHidden:NO];
        }
        [_mileageLbl setHidden:YES];
        [_ringImage setHidden:YES];
        [_pleaseLoginLabel setHidden:YES];
        [self setTitle:[applicationContext objectForKey:(__bridge id)kSecAttrAccount]];
        
        // save the presets to NSUserDefaults
        NSLog(@"updating title and note presets with titles:%@ and notes:%@",[applicationContext objectForKey:@"titles"],[applicationContext objectForKey:@"notes"]);
        NSUserDefaults *defaults = [[NSUserDefaults standardUserDefaults] init];
        [defaults setObject:[applicationContext objectForKey:@"titles"] forKey:@"titles"];
        [defaults setObject:[applicationContext objectForKey:@"notes"] forKey:@"notes"];
        
        // save bool to NSUserDefaults
        NSNumber *submitData = [applicationContext objectForKey:@"submit-data"];
        NSLog(@"saving health-default value: %@ to user defaults",submitData);
        [defaults setObject:submitData forKey:@"submit-data"];
        
        // updating mileage goal
        NSLog(@"saving mileage-goal value: %@ to user defaults",[applicationContext objectForKey:@"goal"]);
        [defaults setObject:[applicationContext objectForKey:@"goal"] forKey:@"mileage-goal"];
        [self didReceiveMileage:currentMileage userAlreadyRan:userAlreadyRan];
        
        // set firstDayOfWeek
        // monday is 1
        // sunday is 0
        [defaults setObject:[applicationContext objectForKey:@"firstDayOfWeek"] forKey:@"firstDayOfWeek"];
        
        // remove already used objects and keys from context so the rest of the dictionary can be added to the keychain
        NSLog(@"removing excess information from context so it can be added to keychain");
        NSMutableDictionary *mutableContextDict = [NSMutableDictionary dictionaryWithDictionary:applicationContext];
        [mutableContextDict removeObjectForKey:@"goal"];
        [mutableContextDict removeObjectForKey:@"logout"];
        [mutableContextDict removeObjectForKey:@"notes"];
        [mutableContextDict removeObjectForKey:@"submit-data"];
        [mutableContextDict removeObjectForKey:@"titles"];
        [mutableContextDict removeObjectForKey:@"firstDayOfWeek"];
        
        // add credentials to keychain
        NSLog(@"adding credentials to keychain");
        [mutableContextDict setObject:[applicationContext objectForKey:@"shoe"] forKey:(__bridge id)kSecAttrComment];
        [mutableContextDict removeObjectForKey:@"shoe"];
        SecItemAdd((__bridge CFDictionaryRef)mutableContextDict, NULL);
    }
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    currentlyVisible = true;
    if (pendingMileageRefresh) {
        NSLog(@"mileage was refreshed while view was not visible, displaying new mileage that was received");
        [self renderMileageRingAndRecommendationWithMileage:currentMileage userAlreadyRan:userAlreadyRan];
        pendingMileageRefresh = false;
    }
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
    currentlyVisible = false;
}

@end



