//
//  AppDelegate.m
//  Logarun
//
//  Created by Andrew Burford on 4/27/16.
//  Copyright © 2016 Andrew Burford. All rights reserved.
//

#import "AppDelegate.h"
@import HealthKit;

@interface AppDelegate () {
    BOOL morning;
}

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    UIUserNotificationType types = (UIUserNotificationType) (UIUserNotificationTypeAlert);
    
    UIUserNotificationSettings *mySettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
    
    [[UIApplication sharedApplication] registerUserNotificationSettings:mySettings];
    
    // grab correct storyboard depending on screen height
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    // display storyboard
    self.window.rootViewController = [storyboard instantiateInitialViewController];
    [self.window makeKeyAndVisible];
    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    return YES;
}

-(void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    NSUserDefaults *defaults  = [[NSUserDefaults standardUserDefaults] init];
    NSCalendar *calendar = [NSCalendar currentCalendar];
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
        NSString *sqlAuthCookieStr = [[NSString alloc] initWithBytes:[(__bridge_transfer NSData *)passwordData bytes] length:[(__bridge NSData *)passwordData length] encoding:NSUTF8StringEncoding];
        
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
            NSString *username = CFDictionaryGetValue(keychainAttrDictionary, @"acct");
            NSDictionary *cookieProperties = [NSDictionary dictionaryWithObjectsAndKeys:sqlAuthCookieStr,NSHTTPCookieValue,@"sqlAuthCookie",NSHTTPCookieName,@"/",NSHTTPCookiePath,[NSURL URLWithString:@"http://www.logarun.com"],NSHTTPCookieOriginURL, nil];
            NSHTTPCookie *sqlAuthCookie = [NSHTTPCookie cookieWithProperties:cookieProperties];
            NSArray *cookiesArray = [NSArray arrayWithObjects:sqlAuthCookie, nil];
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookies:cookiesArray forURL:[NSURL URLWithString:@"http://www.logarun.com"] mainDocumentURL:nil];
            NSURLSession *theSession = [NSURLSession sharedSession];
            
            // first check if it is before 8:00 AM (check yesterday's post) or after 7:00 PM (check today's post)
            NSDate *dateToCheck = [NSDate date];
            int hour = (int)[calendar component:NSCalendarUnitHour fromDate:dateToCheck];
            if (hour <= 7 || hour >= 19) {
                if (hour <= 7) {
                    // before 8:00 AM, check yesterday's post
                    morning = YES;
                    NSDateComponents *yesterday = [[NSDateComponents alloc] init];
                    [yesterday setDay:-1];
                    dateToCheck = [calendar dateByAddingComponents:yesterday toDate:dateToCheck options:0];
                } else if (hour >= 19) {
                    // after 7:00 PM, check today's post
                    morning = NO;
                }
                // if today has not been checked, then proceed to check either today or yesterday unless yesterday was already checked today
                NSDate *simpleDateToday = [calendar dateFromComponents:[calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:[NSDate date]]];
                if ([defaults objectForKey:@"lastFetchDate"] != simpleDateToday && !([defaults boolForKey:@"didFetchForYesterday"] && morning)) {
                    
                    [defaults setBool:morning forKey:@"didFetchForYesterday"];
                    
                    NSDate *simpleDateToCheck = [calendar dateFromComponents:[calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:dateToCheck]];
                    [defaults setObject:simpleDateToCheck forKey:@"lastFetchDate"];
                    
                    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                    [dateFormatter setDateFormat:@"MM/dd/yyyy"];
                    NSString *urlFormattedDateString = [dateFormatter stringFromDate:dateToCheck];
                    
                    NSURLRequest *theRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.logarun.com/edit.aspx?username=%@&date=%@",username,urlFormattedDateString]] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:7];
                    NSLog(@"keychain was found, about to send out request for current run");
                    [[theSession dataTaskWithRequest:theRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                        if (error == nil) {
                            if (data.length != 0) {
                                NSLog(@"successfully received today's current run, checking if user has logged yet");
                                // check if run has been posted yet
                                NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                NSString *dayTitle = [self getValueForId:@"ctl00_Content_c_dayTitle_c_title" inDataString:dataString];
                                NSRange noteInnerHTMLRange = [dataString rangeOfString:[self getInnerHTMLForId:@"ctl00_Content_c_note_c_note" inDataString:dataString]];
                                NSString *note = [dataString substringWithRange:NSMakeRange(noteInnerHTMLRange.location + 2, noteInnerHTMLRange.length - 2)];
                                NSLog(@"note:'%@'title:'%@'",note,dayTitle);
                                if ([[self getValueForId:@"ctl00_Content_c_applications_act1_ctl00_c_decimal" inDataString:dataString] isEqualToString:@"0.00"] && [[self getValueForId:@"ctl00_Content_c_applications_act1_ctl02_c_duration" inDataString:dataString] isEqualToString:@"00:00:00"] && [dayTitle isEqualToString:@""] && [note isEqualToString:@""]) {
                                    // no run has been posted yet, check health kit for any runs
                                    NSLog(@"no run posted yet, checking healthkit for any runs");
                                    if ([HKHealthStore isHealthDataAvailable]) {
                                        HKHealthStore *healthStore = [[HKHealthStore alloc] init];
                                        NSCalendar *calendar = [NSCalendar currentCalendar];
                                        NSDateComponents *components = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:dateToCheck];
                                        NSDate *startDate = [calendar dateFromComponents:components];
                                        NSDate *endDate = [calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:startDate options:0];
                                        HKSampleType *sampleType = [HKSampleType workoutType];
                                        NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionNone];
                                        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:HKWorkoutSortIdentifierTotalDistance ascending:NO];
                                        HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:sampleType predicate:predicate limit:HKObjectQueryNoLimit sortDescriptors:@[sortDescriptor] resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error) {
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                NSLog(@"healthkit returned results:%@",results);
                                                if ([results count] > 0) {
                                                    // post runs found in healthkit and inform user that runs have been posted
                                                    NSMutableArray *tempDistances = [[NSMutableArray alloc] init];
                                                    NSMutableArray *tempDurations = [[NSMutableArray alloc] init];
                                                    for (int i = 0; i < [results count]; i++) {
                                                        double miles = [((HKWorkout*)results[i]).totalDistance doubleValueForUnit:[HKUnit mileUnit]];
                                                        [tempDistances addObject:[NSString stringWithFormat:@"%.2lf",miles]];
                                                        [tempDurations addObject:[self stringFromTimeInterval:((HKWorkout*)results[i]).duration]];
                                                    }
                                                    [self postRunOnDate:dateToCheck username:username dayTitle:dayTitle distances:tempDistances durations:tempDurations dailyNote:note eventValidation:[self getValueForId:@"__EVENTVALIDATION" inDataString:dataString] viewState:[self getValueForId:@"__VIEWSTATE" inDataString:dataString] attempt:1 completionHandler:completionHandler];
                                                    
                                                } else if (!results) {
                                                    NSLog(@"screen is locked so healthkit could not be accessed");
                                                    // set defaults to values that will always cause the next background fetch to proceed
                                                    [defaults setBool:NO forKey:@"didFetchForYesterday"];
                                                    [defaults setObject:[NSDate dateWithTimeIntervalSince1970:0] forKey:@"lastFetchDate"];
                                                    
                                                    // only send notification once
                                                    UILocalNotification *notification = [[UILocalNotification alloc] init];
                                                    if (morning) {
                                                        if ([defaults objectForKey:@"mustCheckHKForDateYesterday"] != simpleDateToCheck) {
                                                            [defaults setObject:simpleDateToCheck forKey:@"mustCheckHKForDateYesterday"];
                                                            notification.alertBody = @"It looks you didn't log your run yesterday";
                                                            [application presentLocalNotificationNow:notification];
                                                        }
                                                    } else {
                                                        if ([defaults objectForKey:@"mustCheckHKForDateToday"] != simpleDateToCheck) {
                                                            [defaults setObject:simpleDateToCheck forKey:@"mustCheckHKForDateToday"];
                                                            notification.alertBody = @"Don't forget to log your run today!";
                                                            [application presentLocalNotificationNow:notification];
                                                        }
                                                    }
                                                    
                                                    completionHandler(UIBackgroundFetchResultNewData);
                                                } else {
                                                    NSLog(@"no runs from healthkit, reminding user to log their run");
                                                    // no runs found in health kit and no run has been posted, create notification to remind user to log their run
                                                    UILocalNotification *notification = [[UILocalNotification alloc] init];
                                                    if (morning) {
                                                        if ([defaults objectForKey:@"mustCheckHKForDateYesterday"] != simpleDateToCheck) {
                                                            [defaults setObject:simpleDateToCheck forKey:@"mustCheckHKForDateYesterday"];
                                                            notification.alertBody = @"It looks you didn't log your run yesterday";
                                                            [application presentLocalNotificationNow:notification];
                                                        }
                                                    } else {
                                                        if ([defaults objectForKey:@"mustCheckHKForDateToday"] != simpleDateToCheck) {
                                                            [defaults setObject:simpleDateToCheck forKey:@"mustCheckHKForDateToday"];
                                                            notification.alertBody = @"Don't forget to log your run today!";
                                                            [application presentLocalNotificationNow:notification];
                                                        }
                                                    }
                                                    completionHandler(UIBackgroundFetchResultNewData);
                                                }
                                            });
                                        }];
                                        [healthStore executeQuery:query];
                                    } else {
                                        // run not posted but health kit not available, create notification to remind user to log their run
                                        NSLog(@"no run posted but healthkit is not available");
                                        UILocalNotification *notification = [[UILocalNotification alloc] init];
                                        if (morning) {
                                            notification.alertBody = @"It looks you didn't log your run yesterday";
                                        } else {
                                            notification.alertBody = @"Don't forget to log your run today!";
                                        }
                                        [application presentLocalNotificationNow:notification];
                                        completionHandler(UIBackgroundFetchResultNewData);
                                    }
                                } else {
                                    // a run has already been posted
                                    NSLog(@"user has already posted a run today");
                                    completionHandler(UIBackgroundFetchResultNewData);
                                }
                            } else {
                                // data string had lenth 0
                                NSLog(@"data string has length 0");
                                // set defaults to values that will always cause the next background fetch to proceed
                                [defaults setBool:NO forKey:@"didFetchForYesterday"];
                                [defaults setObject:[NSDate dateWithTimeIntervalSince1970:0] forKey:@"lastFetchDate"];
                                completionHandler(UIBackgroundFetchResultNoData);
                            }
                        } else {
                            // connection error
                            NSLog(@"connection error");
                            // set defaults to values that will always cause the next background fetch to proceed
                            [defaults setBool:NO forKey:@"didFetchForYesterday"];
                            [defaults setObject:[NSDate dateWithTimeIntervalSince1970:0] forKey:@"lastFetchDate"];
                            completionHandler(UIBackgroundFetchResultFailed);
                        }
                    }] resume];
                } else {
                    // user already sufficiently notified
                    NSLog(@"user already sufficiently notified");
                    completionHandler(UIBackgroundFetchResultFailed);
                }
            } else {
                NSLog(@"it is the middle of the day, don't notify the user");
                completionHandler(UIBackgroundFetchResultFailed);
            }
        } else {
            // weird error
            NSLog(@"weird error with keychain");
            completionHandler(UIBackgroundFetchResultFailed);
        }
        
    } else if (keychainError == errSecItemNotFound) {
        // user has not logged in yet
        NSLog(@"user not logged in");
        completionHandler(UIBackgroundFetchResultFailed);
    }
}

-(void)postRunOnDate:(NSDate*)date username:(NSString*)username dayTitle:(NSString *)title distances:(NSArray<NSString *> *)distances durations:(NSArray<NSString *> *)durations dailyNote:(NSString *)note eventValidation:(NSString *)eventValidation viewState:(NSString *)viewState attempt:(int)attempt completionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    
    int attemptsRequired;
    if ([distances count] == 1) {
        attemptsRequired  = 1;
    } else {
        attemptsRequired = 2 + ((int)[distances count] - 2) * 2;
    }
    
    NSString *bodyData;
    NSUserDefaults *defaults = [[NSUserDefaults standardUserDefaults] init];
    if (attempt < attemptsRequired) {
        if ([defaults boolForKey:@"newUser"]) {
            if (attempt % 2 == 1) {
                bodyData = [NSString stringWithFormat:@"ctl00%%24Content%%24c_scriptManager=ctl00%%24Content%%24c_applications%%24c_appUpdatePanel%%7Cctl00%%24Content%%24c_applications%%24ctl00_Content_c_applications_ctl54&__EVENTTARGET=ctl00%%24Content%%24c_applications%%24ctl00_Content_c_applications_ctl54&"];
            } else {
                bodyData = [NSString stringWithFormat:@"ctl00%%24Content%%24c_scriptManager=ctl00%%24Content%%24c_applications%%24c_appUpdatePanel%%7Cctl00%%24Content%%24c_applications%%24ctl00_Content_c_applications_ctl134&__EVENTTARGET=ctl00%%24Content%%24c_applications%%24ctl00_Content_c_applications_ctl134&"];
            }
        } else {
            if (attempt % 2 == 1) {
                bodyData = [NSString stringWithFormat:@"ctl00%%24Content%%24c_scriptManager=ctl00%%24Content%%24c_applications%%24c_appUpdatePanel%%7Cctl00%%24Content%%24c_applications%%24ctl00_Content_c_applications_ctl02&__EVENTTARGET=ctl00%%24Content%%24c_applications%%24ctl00_Content_c_applications_ctl02&"];
            } else {
                bodyData = [NSString stringWithFormat:@"ctl00%%24Content%%24c_scriptManager=ctl00%%24Content%%24c_applications%%24c_appUpdatePanel%%7Cctl00%%24Content%%24c_applications%%24ctl00_Content_c_applications_ctl82&__EVENTTARGET=ctl00%%24Content%%24c_applications%%24ctl00_Content_c_applications_ctl82&"];
            }
        }
    } else {
        NSLog(@"last attempt");
        bodyData = @"";
    }
    
    bodyData = [bodyData stringByAppendingString:[NSString stringWithFormat:@"__VIEWSTATE=%@&__EVENTVALIDATION=%@&ctl00%%24Content%%24c_dayTitle%%24c_title=%@&ctl00%%24Content%%24c_applications%%24act0%%24c_collapsedHidden=1",[self stringToHex:viewState],[self stringToHex:eventValidation],title]];
    
    for (int act = 1; act <= [distances count]; act++) {
        bodyData = [bodyData stringByAppendingString:[NSString stringWithFormat:@"&ctl00%%24Content%%24c_applications%%24act%d%%24c_collapsedHidden=1&ctl00%%24Content%%24c_applications%%24act%d%%24ctl00%%24c_decimal=%@&ctl00%%24Content%%24c_applications%%24act%d%%24ctl02%%24c_duration=%@",act,act,distances[act - 1],act,durations[act - 1]]];
    }
    
    bodyData = [bodyData stringByAppendingString:[NSString stringWithFormat:@"&ctl00%%24Content%%24c_note%%24c_note=%@",note]];
    
    if (attempt == attemptsRequired) {
        bodyData = [bodyData stringByAppendingString:@"&ctl00%24Content%24c_save=Save"];
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM/dd/yyyy"];
    NSString *urlFormattedDateString = [dateFormatter stringFromDate:date];
    
    NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.logarun.com/Edit.aspx?username=%@&date=%@",username,urlFormattedDateString]]];
    
    // Set the request's content type to application/x-www-form-urlencoded
    [postRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    // Designate the request a POST request and specify its body data
    [postRequest setHTTPMethod:@"POST"];
    [postRequest setHTTPBody:[NSData dataWithBytes:[bodyData UTF8String] length:strlen([bodyData UTF8String])]];
    if (attempt < attemptsRequired) {
        [postRequest setValue:@"Mozilla/5.0" forHTTPHeaderField:@"User-Agent"];
        [postRequest setValue:@"Delta=true" forHTTPHeaderField:@"X-MicrosoftAjax"];
    }
    NSURLSession *theSession = [NSURLSession sharedSession];
    [[theSession dataTaskWithRequest:postRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error == nil) {
            NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            if (dataString.length != 0) {
                NSLog(@"recevied response for attempt:%d of %d",attempt,attemptsRequired);
                if (attempt < attemptsRequired) {
                    [self postRunOnDate:date username:username dayTitle:title distances:distances durations:durations dailyNote:note eventValidation:[self getAbsValueForID:@"__EVENTVALIDATION" inDataString:dataString] viewState:[self getAbsValueForID:@"__VIEWSTATE" inDataString:dataString] attempt:attempt + 1 completionHandler:completionHandler];
                } else {
                    // all runs have been posted, notify that their runs have been saved
                    NSLog(@"healthkit runs have been saved to logarun via background fetch");
                    UILocalNotification *notification = [[UILocalNotification alloc] init];
                    switch ([distances count]) {
                        case 1:
                            if (morning) {
                                notification.alertBody = [NSString stringWithFormat:@"Your %@ run yesterday was automatically saved by Run Logger",distances[0]];
                            } else {
                                notification.alertBody = [NSString stringWithFormat:@"Your %@ run was automatically saved by Run Logger",distances[0]];
                            }
                            break;
                        case 2:
                            if (morning) {
                                notification.alertBody = [NSString stringWithFormat:@"Your %@ and %@ runs yesterday were automatically saved by Run Logger",distances[0],distances[1]];
                            } else {
                                notification.alertBody = [NSString stringWithFormat:@"Your %@ and %@ runs were automatically saved by Run Logger",distances[0],distances[1]];
                            }
                            break;
                        default:
                            notification.alertBody = @"Your ";
                            [distances enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                                if (idx < [distances count] - 1) {
                                    notification.alertBody = [notification.alertBody stringByAppendingString:[NSString stringWithFormat:@"%@, ",obj]];
                                } else {
                                    notification.alertBody = [notification.alertBody stringByAppendingString:[NSString stringWithFormat:@"and %@ ",obj]];
                                }
                            }];
                            if (morning) {
                                notification.alertBody = [notification.alertBody stringByAppendingString:@"mile runs yesterday were automatically saved by Run Logger"];
                            } else {
                                notification.alertBody = [notification.alertBody stringByAppendingString:@"mile runs were automatically saved by Run Logger"];
                            }
                            break;
                    }
                    NSLog(@"presenting notification:%@ with alert:%@",notification,notification.alertBody);
                    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                    completionHandler(UIBackgroundFetchResultNewData);
                }
            } else {
                completionHandler(UIBackgroundFetchResultNoData);
            }
        } else {
            completionHandler(UIBackgroundFetchResultFailed);
        }
    }] resume];
}

-(NSString*)getAbsValueForID:(NSString*)theID inDataString:(NSString*)dataString {
    NSRange valueStartRange = [dataString rangeOfString:[NSString stringWithFormat:@"%@|",theID]];
    NSString *returnString = @"";
    if (valueStartRange.location != NSNotFound) {
        valueStartRange.location = valueStartRange.location + valueStartRange.length;
        NSRange valueEndRange = [dataString rangeOfString:@"|" options:NSLiteralSearch range:NSMakeRange(valueStartRange.location, dataString.length - valueStartRange.location)];
        if (valueEndRange.location != NSNotFound) {
            returnString = [dataString substringWithRange:NSMakeRange(valueStartRange.location, valueEndRange.location - valueStartRange.location)];
            returnString = [self stringToHex:returnString];
        } else {
            NSLog(@"failed to find |value| for id:%@",theID);
            returnString = @"";
        }
    } else {
        NSLog(@"failed to find |value| for id:%@",theID);
        returnString = @"";
    }
    return returnString;
}

- (NSString *)stringFromTimeInterval:(NSTimeInterval)interval {
    NSInteger ti = (NSInteger)interval;
    NSInteger seconds = ti % 60;
    NSInteger minutes = (ti / 60) % 60;
    NSInteger hours = (ti / 3600);
    return [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)hours, (long)minutes, (long)seconds];
}

-(NSString*)getInnerHTMLForId:(NSString*)theID inDataString:(NSString*)dataString{
    NSRange innerHTMLStart = [dataString rangeOfString:[NSString stringWithFormat:@"id=\"%@\"",theID]];
    if (innerHTMLStart.location == NSNotFound) {
        return @"";
    }
    NSRange beginningOfTagName = [dataString rangeOfString:@"<" options:NSBackwardsSearch range:NSMakeRange(0, innerHTMLStart.location)];
    NSRange endofTagName = [dataString rangeOfString:@" " options:NSLiteralSearch range:NSMakeRange(beginningOfTagName.location, innerHTMLStart.location - beginningOfTagName.location)];
    NSString *idTagName = [dataString substringWithRange:NSMakeRange(beginningOfTagName.location + 1, endofTagName.location - beginningOfTagName.location - 1)];
    NSRange innerHTMLEnd = [dataString rangeOfString:[NSString stringWithFormat:@"</%@",idTagName] options:NSLiteralSearch range:NSMakeRange(innerHTMLStart.location+innerHTMLStart.length,dataString.length-innerHTMLStart.location-innerHTMLStart.length)];
    NSRange endOfStartTag = [dataString rangeOfString:@">" options:NSLiteralSearch range:NSMakeRange(innerHTMLStart.location, dataString.length - innerHTMLStart.location)];
    return [dataString substringWithRange:NSMakeRange(endOfStartTag.location + 1,innerHTMLEnd.location-endOfStartTag.location - 1)];
}

-(NSString*)getValueForId:(NSString*)theID inDataString:(NSString*)dataString{
    NSRange IDStart = [dataString rangeOfString:[NSString stringWithFormat:@"id=\"%@\"",theID]];
    if (IDStart.location == NSNotFound) {
        return @"";
    } else {
        NSRange tagStart = [dataString rangeOfString:@"<" options:NSBackwardsSearch range:NSMakeRange(0,IDStart.location)];
        NSRange tagEnd = [dataString rangeOfString:@">" options:NSLiteralSearch range:NSMakeRange(IDStart.location, dataString.length - IDStart.location)];
        NSRange valueStart = [dataString rangeOfString:@"value=\"" options:NSLiteralSearch range:NSMakeRange(tagStart.location,tagEnd.location - tagStart.location)];
        if (valueStart.location != NSNotFound) {
            NSRange valueEnd = [dataString rangeOfString:@"\"" options:NSLiteralSearch range:NSMakeRange(valueStart.location+valueStart.length, dataString.length-valueStart.location-valueStart.length)];
            NSString *returnString = [dataString substringWithRange:NSMakeRange(valueStart.location+valueStart.length,valueEnd.location - valueStart.location - valueStart.length)];
            return returnString;
        } else {
            return @"";
        }
    }
}

- (NSString *) stringToHex:(NSString *)str
{
    NSUInteger len = [str length];
    unichar *chars = malloc(len * sizeof(unichar));
    [str getCharacters:chars];
    
    NSMutableString *hexString = [[NSMutableString alloc] init];
    
    for(NSUInteger i = 0; i < len; i++ )
    {
        if ([[NSString stringWithFormat:@"%x", chars[i]] isEqual:@"3d"] || [[NSString stringWithFormat:@"%x", chars[i]] isEqual:@"2b"] || [[NSString stringWithFormat:@"%x", chars[i]] isEqual:@"2f"]) {
            [hexString appendString:[[NSString stringWithFormat:@"%%%x", chars[i]] uppercaseString]];
        } else {
            [hexString appendString:[str substringWithRange:NSMakeRange(i,1)]];
            
        }
    }
    free(chars);
    
    return hexString;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
