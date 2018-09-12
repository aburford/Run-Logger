//
//  LARSession.m
//  Logarun
//
//  Created by Andrew Burford on 4/28/16.
//  Copyright © 2016 Andrew Burford. All rights reserved.
//

#import "LARSession.h"
#import "ViewController.h"
#import "NSString+HTML.h"

@implementation LARSession {
    NSString *bodyData;
    NSURLSession *theURLSession;
    NSMutableDictionary *keychainDictionaryForWatch;
    BOOL defaultShoeFound;
    BOOL loginSuccess;
    NSString *preferencesDataString;
    BOOL cancelingTasks;
}

@synthesize username;

-(void)initStuff {
    // called once every time app is opened, or user logs in
    // getRunTasks = [[NSMutableArray alloc] init];
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

-(void)getCurrentMileageToDelegate:(id<LARSessionDelegateProtocol>)delegate {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy/MM"];
    NSDate *today = [NSDate date];
    NSString *formattedDateString = [dateFormatter stringFromDate:today];
    
    NSURLRequest *theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.logarun.com/calendars/%@/%@",username,formattedDateString]] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
    NSURLSession *newSession = [NSURLSession sharedSession];
    [[newSession dataTaskWithRequest:theRequest
                   completionHandler:^(NSData *data,
                                       NSURLResponse *response,
                                       NSError *error) {
                       if (data.length != 0) {
                       double mileage = 0;
                       NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                       NSRange result = [dataString rangeOfString:@"<div class=\"day today"];
                       if (result.location == NSNotFound) {
                           // date is not in current month, get next month page
                           NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                           [dateFormatter setDateFormat:@"yyyy/MM"];
                           
                           
                           NSDate *originalDate = [NSDate date];
                           NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
                           [dateComponents setMonth:1];
                           NSCalendar *calendar = [NSCalendar currentCalendar];
                           NSDate *newDate = [calendar dateByAddingComponents:dateComponents toDate:originalDate options:0];
                           
                           NSString *formattedDateString = [dateFormatter stringFromDate:newDate];
                           
                           NSURLRequest *theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.logarun.com/calendars/%@/%@",username,formattedDateString]] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
                           NSURLSession *newSession = [NSURLSession sharedSession];
                           [[newSession dataTaskWithRequest:theRequest
                                          completionHandler:^(NSData *data,
                                                              NSURLResponse *response,
                                                              NSError *error) {
                                              double mileage = 0;
                                              NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                              NSRange result = [dataString rangeOfString:@"<div class=\"day today"];
                                              NSInteger today = [[dataString substringWithRange:NSMakeRange(result.location-21, 2)] integerValue];
                                              NSRange searchStringRange = NSMakeRange(0, dataString.length);
                                              result = [[dataString substringWithRange:searchStringRange] rangeOfString:@"<td class=\"totCell"];
                                              while (result.location != NSNotFound) {
                                                  if ([[dataString substringWithRange:NSMakeRange(result.location+result.length+39, 2)]integerValue] > today) {
                                                      mileage = [[dataString substringWithRange:NSMakeRange(result.location+result.length+118, 4)]doubleValue];
                                                      break;
                                                  }
                                                  searchStringRange.location = result.location+result.length;
                                                  searchStringRange.length = dataString.length - searchStringRange.location;
                                                  result = [dataString rangeOfString:@"<td class=\"totCell" options:NSLiteralSearch range:searchStringRange];
                                              }
                                              
                                              // now find if user has ran yet today
                                              // to do this we will check if the day title is blank AND if the note is blank AND if no other input is entered
                                              // first check day title
                                              NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                                              [dateFormatter setDateFormat:@"LL/d\""];
                                              NSString *searchString = [dateFormatter stringFromDate:[NSDate date]];
                                              NSRange searchRange = [dataString rangeOfString:searchString];
                                              searchRange = NSMakeRange(searchRange.location, dataString.length - searchRange.location);
                                              NSString *dayTitle = [self getInnerHTMLForClass:@"dayTitle" inDataString:dataString withRange:searchRange];
                                              if ([dayTitle  isEqual: @""]) {
                                                  // day title blank, now check for a daily note
                                                  NSRange divStartRange = [dataString rangeOfString:@"<div class=\"body\" title" options:NSLiteralSearch range:searchRange];
                                                  NSString *nextCharacter = [dataString substringWithRange:NSMakeRange(divStartRange.location + divStartRange.length, 4)];
                                                  if ([nextCharacter isEqualToString:@"=\"\">"]) {
                                                      // daily note blank, now check for other input
                                                      NSString *otherInput = [self getInnerHTMLForClass:@"body" inDataString:dataString withRange:searchRange];
                                                      if (otherInput.length == 11) {
                                                          // everything is blank, user has not ran yet
                                                          [delegate didReceiveMileage:mileage userAlreadyRan:false];
                                                      } else {
                                                          // there is other input
                                                          NSLog(@"other input found");
                                                          [delegate didReceiveMileage:mileage userAlreadyRan:true];
                                                      }
                                                  } else {
                                                      // daily note is not blank
                                                      NSLog(@"daily note found");
                                                      [delegate didReceiveMileage:mileage userAlreadyRan:true];
                                                  }
                                              } else {
                                                  // day title is not blank
                                                  NSLog(@"day title found");
                                                  [delegate didReceiveMileage:mileage userAlreadyRan:true];
                                              }
                                              
                                          }] resume];
                           
                       } else {
                           NSInteger today = [[dataString substringWithRange:NSMakeRange(result.location-21, 2)] integerValue];
                           NSRange searchStringRange = NSMakeRange(0, dataString.length);
                           result = [[dataString substringWithRange:searchStringRange] rangeOfString:@"<td class=\"totCell"];
                           while (result.location != NSNotFound) {
                               if ([[dataString substringWithRange:NSMakeRange(result.location+result.length+39, 2)]integerValue] > today) {
                                   mileage = [[dataString substringWithRange:NSMakeRange(result.location+result.length+118, 4)]doubleValue];
                                   break;
                               }
                               searchStringRange.location = result.location + result.length;
                               searchStringRange.length = dataString.length - searchStringRange.location;
                               result = [dataString rangeOfString:@"<td class=\"totCell" options:NSLiteralSearch range:searchStringRange];
                           }
                           // now find if user has ran yet today
                           // to do this we will check if the day title is blank AND if the note is blank AND if no other input is entered
                           // first check day title
                           NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                           [dateFormatter setDateFormat:@"LL/dd\""];
                           NSString *searchString = [dateFormatter stringFromDate:[NSDate date]];
                           NSLog(@"searching for date:%@",searchString);
                           NSRange searchRange = [dataString rangeOfString:searchString];
                           searchRange = NSMakeRange(searchRange.location, dataString.length - searchRange.location);
                           NSString *dayTitle = [self getInnerHTMLForClass:@"dayTitle" inDataString:dataString withRange:searchRange];
                           if ([dayTitle  isEqual: @""]) {
                               // day title blank, now check for a daily note
                               NSRange divStartRange = [dataString rangeOfString:@"<div class=\"body\" title" options:NSLiteralSearch range:searchRange];
                               NSString *nextCharacter = [dataString substringWithRange:NSMakeRange(divStartRange.location + divStartRange.length, 4)];
                               if ([nextCharacter isEqualToString:@"=\"\">"]) {
                                   // daily note blank, now check for other input
                                   NSString *otherInput = [self getInnerHTMLForClass:@"body" inDataString:dataString withRange:searchRange];
                                   if (otherInput.length == 11) {
                                       // everything is blank, user has not ran yet
                                       [delegate didReceiveMileage:mileage userAlreadyRan:false];
                                   } else {
                                       // there is other input
                                       NSLog(@"other input found");
                                       [delegate didReceiveMileage:mileage userAlreadyRan:true];
                                   }
                               } else {
                                   // daily note is not blank
                                   NSLog(@"daily note found");
                                   [delegate didReceiveMileage:mileage userAlreadyRan:true];
                               }
                           } else {
                               // day title is not blank
                               NSLog(@"day title found");
                               [delegate didReceiveMileage:mileage userAlreadyRan:true];
                           }

                       }
                       } else {
                           NSLog(@"mileage request timed out");
                           [delegate didReceiveMileage:-1 userAlreadyRan:nil];
                       }
                   }] resume];
    
}

-(void)loginWithUsername:(NSString *)user password:(NSString *)pass delegate:(id<LARSessionDelegateProtocol>)sender {
    [self initStuff];
    username = user;
    self.delegate = sender;
    loginSuccess = false;
    // In body data for the 'application/x-www-form-urlencoded' content type,
    // form fields are separated by an ampersand. Note the absence of a
    // leading ampersand.
    bodyData = [NSString stringWithFormat:@"SubmitLogon=true&LoginName=%@&Password=%@&LoginNow=Login",username,pass];
    NSLog(@"body data for login request:%@",bodyData);
    NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://www.logarun.com/logon.aspx"]];
    // Set the request's content type to application/x-www-form-urlencoded
    [postRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    // Designate the request a POST request and specify its body data
    [postRequest setHTTPMethod:@"POST"];
    [postRequest setHTTPBody:[NSData dataWithBytes:[bodyData UTF8String] length:strlen([bodyData UTF8String])]];
    
    // Initialize the NSURLConnection and proceed as described in
    // Retrieving the Contents of a URL
    
    // create the connection with the request
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
    [[session dataTaskWithRequest:postRequest
            completionHandler:^(NSData *data,
                                NSURLResponse *response,
                                NSError *error) {
                if (!loginSuccess) {
                    // login failed
                    NSLog(@"login failed because request timed out");
                    [self.delegate sessionDidLogin:0];
                }
            }] resume];
    theURLSession=session;
    if([WCSession isSupported]){
        self.watchSession = [WCSession defaultSession];
        self.watchSession.delegate = self;
        [self.watchSession activateSession];
    }

}

-(void)createAccountWithUsername:(NSString *)user displayName:(NSString *)displayName email:(NSString *)email password:(NSString *)password private:(BOOL)private gender:(NSString *)gender delegate:(id<LARSessionDelegateProtocol>)delegate {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.logarun.com/signup.aspx"]];
    NSURLSession *newSession = [NSURLSession sharedSession];
    [[newSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSString *eventValidation = [self getValueForId:@"__EVENTVALIDATION" inDataString:dataString];
        NSString *viewState = [self getValueForId:@"__VIEWSTATE" inDataString:dataString];
        eventValidation = [self stringToHex:eventValidation];
        viewState = [self stringToHex:viewState];
        NSString *body;
        if (private) {
            body = [NSString stringWithFormat:@"__VIEWSTATE=%@&__EVENTVALIDATION=%@&ctl00%%24Content%%24c_username=%@&ctl00%%24Content%%24c_displayName=%@&ctl00%%24Content%%24c_email=%@&ctl00%%24Content%%24c_password=%@&ctl00%%24Content%%24c_password2=%@&ctl00%%24Content%%24c_gender=%@&ctl00%%24Content%%24ctl01=Register",viewState,eventValidation,user,displayName,email,password,password,gender];
        } else {
            body = [NSString stringWithFormat:@"__VIEWSTATE=%@&__EVENTVALIDATION=%@&ctl00%%24Content%%24c_username=%@&ctl00%%24Content%%24c_displayName=%@&ctl00%%24Content%%24c_email=%@&ctl00%%24Content%%24c_password=%@&ctl00%%24Content%%24c_password2=%@&ctl00%%24Content%%24c_private=on&ctl00%%24Content%%24c_gender=%@&ctl00%%24Content%%24ctl01=Register",viewState,eventValidation,user,displayName,email,password,password,gender];
        }
        NSLog(@"body:%@",body);
        NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://www.logarun.com/signup.aspx"]];
        [postRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        [postRequest setHTTPMethod:@"POST"];
        [postRequest setHTTPBody:[NSData dataWithBytes:[body UTF8String] length:strlen([body UTF8String])]];
        
        
        [[newSession dataTaskWithRequest:postRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            // first check if successful by searching for <title>User Options Page - LogARun.com</title>, if not then check for already exists, if not assume email
            if (dataString.length > 0) {
                NSRange successRange = [dataString rangeOfString:@"<title>User Options Page - LogARun.com</title>"];
                if (successRange.location == NSNotFound) {
                    // failed, check for duplicate account
                    NSRange duplicateNameRange = [dataString rangeOfString:@"already exists"];
                    if (duplicateNameRange.location == NSNotFound) {
                        // no duplicate username, failed for other reasons
                        NSLog(@"failed for other reasons");
                        [delegate accountCreationReceivedResponse:CreationFailedOther];
                    } else {
                        // duplicate account name
                        NSLog(@"duplicate username");
                        [delegate accountCreationReceivedResponse:CreationFailedDuplicateName];
                    }
                } else {
                    // success
                    [delegate accountCreationReceivedResponse:CreationSucceeded];
                }
            } else {
                NSLog(@"account creation failed no connection");
                [delegate accountCreationReceivedResponse:CreationFailedNoConnection];
            }
        }] resume];
        
        
    }] resume];
}

-(void)loginWithUsername:(NSString *)user sqlAuth:(NSString *)sqlAuth delegate:(id <LARSessionDelegateProtocol>)delegate {
    [self initStuff];
    username = user;
    self.delegate = delegate;
    NSDictionary *cookieProperties = [NSDictionary dictionaryWithObjectsAndKeys:sqlAuth,NSHTTPCookieValue,@"sqlAuthCookie",NSHTTPCookieName,@"/",NSHTTPCookiePath,[NSURL URLWithString:@"http://www.logarun.com"],NSHTTPCookieOriginURL, nil];
    NSHTTPCookie *sqlAuthCookie = [NSHTTPCookie cookieWithProperties:cookieProperties];
    NSArray *cookiesArray = [NSArray arrayWithObjects:sqlAuthCookie, nil];
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookies:cookiesArray forURL:[NSURL URLWithString:@"http://www.logarun.com"] mainDocumentURL:nil];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
    theURLSession=session;
    if([WCSession isSupported] && !self.watchSession){
        self.watchSession = [WCSession defaultSession];
        self.watchSession.delegate = self;
        [self.watchSession activateSession];
    }
    
    NSMutableDictionary *keyChainDictionary = [[NSMutableDictionary alloc] init];
    [keyChainDictionary setObject:(__bridge id)kSecClassInternetPassword forKey:(__bridge id)kSecClass];
    [keyChainDictionary setObject:username forKey:(__bridge id)kSecAttrAccount];
    [keyChainDictionary setObject:sqlAuthCookie.name forKey:(__bridge id)kSecAttrLabel];
    [keyChainDictionary setObject:(__bridge id)kSecAttrAccessibleAlways forKey:(__bridge id)kSecAttrAccessible];
    [keyChainDictionary setObject:[sqlAuthCookie.value dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecValueData];
    
    _shoeDictionary = [[NSMutableDictionary alloc] init];
    [self getShoeXMLForAccount:keyChainDictionary];
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest *))completionHandler {
    NSLog(@"willPerformHTTPRedirection");
    if (response.statusCode == 302 && [response.URL.absoluteString isEqualToString:@"http://www.logarun.com/logon.aspx"]) {
        NSLog(@"login succeeded, creating keychain");
        loginSuccess = true;
        NSArray *cookies = [NSHTTPCookie cookiesWithResponseHeaderFields:[response allHeaderFields] forURL:[response URL]];
        
        NSHTTPCookie *sqlAuthCookie = [[NSHTTPCookie alloc] init];
        for (NSHTTPCookie* cookie in cookies) {
            if ([cookie.name isEqualToString:@"sqlAuthCookie"]) {
                sqlAuthCookie = cookie;
            }
        }
        if (!sqlAuthCookie) {
            for (NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies])
            {
                if ([cookie.name isEqualToString:@"sqlAuthCookie"]) {
                    sqlAuthCookie = cookie;
                }
            }
        }

        //create keychain
        NSMutableDictionary *keyChainDictionary = [[NSMutableDictionary alloc] init];
        [keyChainDictionary setObject:(__bridge id)kSecClassInternetPassword forKey:(__bridge id)kSecClass];
        [keyChainDictionary setObject:username forKey:(__bridge id)kSecAttrAccount];
        [keyChainDictionary setObject:sqlAuthCookie.name forKey:(__bridge id)kSecAttrLabel];
        [keyChainDictionary setObject:(__bridge id)kSecAttrAccessibleAlways forKey:(__bridge id)kSecAttrAccessible];
        [keyChainDictionary setObject:[sqlAuthCookie.value dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecValueData];
        
        // add keychain
        SecItemAdd((__bridge CFDictionaryRef)keyChainDictionary, NULL);
        
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookies:cookies forURL:[response URL] mainDocumentURL:nil];

        // now we want to make sure the daily log settings are set to Health,Run in LogARun, then after that we can move on to getting the shoe data
        NSURLRequest *theRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.logarun.com/configuration.aspx"] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60];
        NSLog(@"first request to fix health settings");
        [[theURLSession dataTaskWithRequest:theRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (data.length != 0) {
                NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                NSLog(@"creating second request to fix health settings");
                NSString *postData = @"ctl00%24Content%24ctl00=ctl00%24Content%24ctl00%7Cctl00%24Content%24c_nav%24ctl03&__EVENTTARGET=ctl00%24Content%24c_nav%24ctl03&__VIEWSTATEFIELDCOUNT=8&__VIEWSTATE=";
                postData = [postData stringByAppendingString:[self getValueForId:@"__VIEWSTATE" inDataString:dataString]];
                // add all 7 viewstates
                for (int i = 1; i <= 7; i++) {
                    NSString *viewState = [NSString stringWithFormat:@"__VIEWSTATE%d",i];
                    postData = [postData stringByAppendingString:[NSString stringWithFormat:@"&%@=%@",viewState,[self getValueForId:viewState inDataString:dataString]]];
                }
                
                postData = [postData stringByAppendingString:@"&__EVENTVALIDATION="];
                postData = [postData stringByAppendingString:[self getValueForId:@"__EVENTVALIDATION" inDataString:dataString]];
                NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://www.logarun.com/configuration.aspx"]];
                [postRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
                [postRequest setHTTPMethod:@"POST"];
                [postRequest setHTTPBody:[NSData dataWithBytes:[postData UTF8String] length:strlen([postData UTF8String])]];
                [postRequest setValue:@"Mozilla/5.0" forHTTPHeaderField:@"User-Agent"];
                [postRequest setValue:@"Delta=true" forHTTPHeaderField:@"X-MicrosoftAjax"];
                NSLog(@"created second request to fix health settings");
                [[theURLSession dataTaskWithRequest:postRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                    if (data.length != 0) {
                        NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                        NSLog(@"creating third request to fix health settings");
                        NSString *postData = @"ctl00%24Content%24c_selected=Daily+Log&ctl00%24Content%24ctl04%24c_activities%24c_value=Health%2CRun&ctl00%24Content%24c_submit=Submit&__VIEWSTATEFIELDCOUNT=8&__VIEWSTATE=";
                        postData = [postData stringByAppendingString:[self getAbsValueForID:@"__VIEWSTATE" inDataString:dataString]];
                        int viewStates = (int)[[self getAbsValueForID:@"__VIEWSTATEFIELDCOUNT" inDataString:dataString] integerValue];
                        for (int i = 1; i <= viewStates - 1; i++) {
                            NSString *viewState = [NSString stringWithFormat:@"__VIEWSTATE%d",i];
                            postData = [postData stringByAppendingString:[NSString stringWithFormat:@"&%@=%@",viewState,[self getAbsValueForID:viewState inDataString:dataString]]];
                        }
                        postData = [postData stringByAppendingString:@"&__EVENTVALIDATION="];
                        postData = [postData stringByAppendingString:[self getAbsValueForID:@"__EVENTVALIDATION" inDataString:dataString]];
                        NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://www.logarun.com/configuration.aspx"]];
                        [postRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
                        [postRequest setHTTPMethod:@"POST"];
                        [postRequest setHTTPBody:[NSData dataWithBytes:[postData UTF8String] length:strlen([postData UTF8String])]];
                        NSLog(@"created third request to fix health settings");
                        [[theURLSession dataTaskWithRequest:postRequest] resume];
                    } else {
                        [self.delegate sessionDidLogin:0];
                    }
                }] resume];
                _shoeDictionary = [[NSMutableDictionary alloc] init];
                [self getShoeXMLForAccount:(NSDictionary*)keyChainDictionary];
            } else {
                [self.delegate sessionDidLogin:0];
            }
        }] resume];
    } else if ([response.URL.absoluteString isEqualToString:@"http://www.logarun.com/logon.aspx"]) {
        NSLog(@"wrong password");
        [self.delegate sessionDidLogin:0];
    }
    NSLog(@"done handling redirection");
    completionHandler(request);
}

-(void)getCommentsPermissionsToDelegate:(id<LARSessionDelegateProtocol>)delegate {
    NSURLRequest *theRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.logarun.com/configuration.aspx"] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60];
    [[theURLSession dataTaskWithRequest:theRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (dataString.length != 0) {
            NSString *postData = @"ctl00%24Content%24ctl00=ctl00%24Content%24ctl00%7Cctl00%24Content%24c_nav%24ctl09&__EVENTTARGET=ctl00%24Content%24c_nav%24ctl09&__VIEWSTATEFIELDCOUNT=8&__VIEWSTATE=";
            postData = [postData stringByAppendingString:[self getValueForId:@"__VIEWSTATE" inDataString:dataString]];
            // add all 7 viewstates
            for (int i = 1; i <= 7; i++) {
                NSString *viewState = [NSString stringWithFormat:@"__VIEWSTATE%d",i];
                postData = [postData stringByAppendingString:[NSString stringWithFormat:@"&%@=%@",viewState,[self getValueForId:viewState inDataString:dataString]]];
            }
            
            postData = [postData stringByAppendingString:@"&__EVENTVALIDATION="];
            postData = [postData stringByAppendingString:[self getValueForId:@"__EVENTVALIDATION" inDataString:dataString]];
            NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://www.logarun.com/configuration.aspx"]];
            [postRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
            [postRequest setHTTPMethod:@"POST"];
            [postRequest setHTTPBody:[NSData dataWithBytes:[postData UTF8String] length:strlen([postData UTF8String])]];
            [postRequest setValue:@"Mozilla/5.0" forHTTPHeaderField:@"User-Agent"];
            [postRequest setValue:@"Delta=true" forHTTPHeaderField:@"X-MicrosoftAjax"];
            [[theURLSession dataTaskWithRequest:postRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                if (data.length != 0) {
                    NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    preferencesDataString = dataString;
                    // read permissions
                    NSRange IDStart = [dataString rangeOfString:@"selected=\"selected\""];
                    NSRange tagStart = [dataString rangeOfString:@"<" options:NSBackwardsSearch range:NSMakeRange(0,IDStart.location)];
                    NSRange tagEnd = [dataString rangeOfString:@">" options:NSLiteralSearch range:NSMakeRange(IDStart.location, dataString.length - IDStart.location)];
                    NSRange valueStart = [dataString rangeOfString:@"value=\"" options:NSLiteralSearch range:NSMakeRange(tagStart.location,tagEnd.location - tagStart.location)];
                    NSRange valueEnd = [dataString rangeOfString:@"\"" options:NSLiteralSearch range:NSMakeRange(valueStart.location+valueStart.length, dataString.length-valueStart.location-valueStart.length)];
                    NSString *readPermission = [dataString substringWithRange:NSMakeRange(valueStart.location+valueStart.length,valueEnd.location - valueStart.location - valueStart.length)];
                    CommentPermission read;
                    if ([readPermission isEqualToString:@"Do whatever my default is"]) {
                        read = CommentPermissionDefault;
                    } else if ([readPermission isEqualToString:@"Share with no one"]) {
                        read = CommentPermissionNoOne;
                    } else if ([readPermission isEqualToString:@"Share with people who are designated as coaches of mine"]) {
                        read = CommentPermissionCoaches;
                    } else if ([readPermission isEqualToString:@"Share with people who are on any teams I am on"]) {
                        read = CommentPermissionTeamMembers;
                    } else if ([readPermission isEqualToString:@"Share with all registered users"]) {
                        read = CommentPermissionAllUsers;
                    } else if ([readPermission isEqualToString:@"Share with everyone"]) {
                        read = CommentPermissionEveryone;
                    }
                    
                    // write permissions
                    IDStart = [dataString rangeOfString:@"selected=\"selected\"" options:NSLiteralSearch range:NSMakeRange(tagEnd.location, dataString.length - tagEnd.location)];
                    tagStart = [dataString rangeOfString:@"<" options:NSBackwardsSearch range:NSMakeRange(0,IDStart.location)];
                    tagEnd = [dataString rangeOfString:@">" options:NSLiteralSearch range:NSMakeRange(IDStart.location, dataString.length - IDStart.location)];
                    valueStart = [dataString rangeOfString:@"value=\"" options:NSLiteralSearch range:NSMakeRange(tagStart.location,tagEnd.location - tagStart.location)];
                    valueEnd = [dataString rangeOfString:@"\"" options:NSLiteralSearch range:NSMakeRange(valueStart.location+valueStart.length, dataString.length-valueStart.location-valueStart.length)];
                    NSString *writePermission = [dataString substringWithRange:NSMakeRange(valueStart.location+valueStart.length,valueEnd.location - valueStart.location - valueStart.length)];
                    CommentPermission write;
                    if ([writePermission isEqualToString:@"Do whatever my default is"]) {
                        write = CommentPermissionDefault;
                    } else if ([writePermission isEqualToString:@"Share with no one"]) {
                        write = CommentPermissionNoOne;
                    } else if ([writePermission isEqualToString:@"Share with people who are designated as coaches of mine"]) {
                        write = CommentPermissionCoaches;
                    } else if ([writePermission isEqualToString:@"Share with people who are on any teams I am on"]) {
                        write = CommentPermissionTeamMembers;
                    } else if ([writePermission isEqualToString:@"Share with all registered users"]) {
                        write = CommentPermissionAllUsers;
                    } else if ([writePermission isEqualToString:@"Share with everyone"]) {
                        write = CommentPermissionEveryone;
                    }
                    NSLog(@"read:%@,write:%@",readPermission,writePermission);
                    [delegate didReceiveCommentViewPermissions:read writePermissions:write];
                } else {
                    // failed
                    [delegate preferencesUpdated:NO];
                }
            }] resume];
        } else {
            // failed
            [delegate preferencesUpdated:NO];
        }
    }] resume];
}

-(NSString*)commentPermissionEnumToString:(CommentPermission)permission {
    NSString *writePermission;
    if (permission == CommentPermissionDefault) {
        writePermission = @"Do whatever my default is";
    } else if (permission == CommentPermissionNoOne) {
        writePermission = @"Share with no one";
    } else if (permission == CommentPermissionCoaches) {
        writePermission = @"Share with people who are designated as coaches of mine";
    } else if (permission == CommentPermissionTeamMembers) {
        writePermission = @"Share with people who are on any teams I am on";
    } else if (permission == CommentPermissionAllUsers) {
        writePermission = @"Share with all registered users";
    } else if (permission == CommentPermissionEveryone) {
        writePermission = @"Share with everyone";
    }
    return writePermission;
}

-(void)postCommentReadPermission:(int)read writePermission:(int)write dayOfWeek:(int)weekday delegate:(id<LARSessionDelegateProtocol>)delegate{
    // first post comment permissions
    NSString *dataString = preferencesDataString;
    NSString *postData = @"ctl00%24Content%24c_selected=Comments&ctl00%24Content%24ctl07%24c_permissions=";
    // read
    postData = [postData stringByAppendingString:[self commentPermissionEnumToString:read]];
    postData = [postData stringByAppendingString:@"&ctl00%24Content%24ctl07%24ctl00%24c_permissions="];
    // write
    postData = [postData stringByAppendingString:[self commentPermissionEnumToString:write]];
    postData = [postData stringByAppendingString:@"&ctl00%24Content%24c_submit=Submit&__VIEWSTATEFIELDCOUNT=8&__VIEWSTATE="];
    postData = [postData stringByAppendingString:[self getAbsValueForID:@"__VIEWSTATE" inDataString:dataString]];
    for (int i = 1; i <= 7; i++) {
        NSString *viewState = [NSString stringWithFormat:@"__VIEWSTATE%d",i];
        postData = [postData stringByAppendingString:[NSString stringWithFormat:@"&%@=%@",viewState,[self getAbsValueForID:viewState inDataString:dataString]]];
    }
    postData = [postData stringByAppendingString:@"&__EVENTVALIDATION="];
    postData = [postData stringByAppendingString:[self getAbsValueForID:@"__EVENTVALIDATION" inDataString:dataString]];
    NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://www.logarun.com/configuration.aspx"]];
    [postRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [postRequest setHTTPMethod:@"POST"];
    [postRequest setHTTPBody:[NSData dataWithBytes:[postData UTF8String] length:strlen([postData UTF8String])]];
    [[theURLSession dataTaskWithRequest:postRequest] resume];
    
    // then update the first day of the week
    [[theURLSession dataTaskWithURL:[NSURL URLWithString:@"http://www.logarun.com/xml.ashx?type=options"] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data.length != 0) {
            NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            dataString = [dataString substringFromIndex:38];
            NSRange weekdayRange = [dataString rangeOfString:@"firstDayOfWeek=\""];
            NSString *postDataStr = [dataString substringWithRange:NSMakeRange(0, weekdayRange.location + weekdayRange.length)];
            postDataStr = [postDataStr stringByAppendingString:[NSString stringWithFormat:@"%i",weekday]];
            postDataStr = [postDataStr stringByAppendingString:[dataString substringWithRange:NSMakeRange(weekdayRange.location + weekdayRange.length + 1, dataString.length - weekdayRange.location - weekdayRange.length - 1)]];
            NSLog(@"post data:%@",postDataStr);
            NSMutableURLRequest *postRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://www.logarun.com/xml.ashx?type=optionspost"]];
            [postRequest setHTTPMethod:@"POST"];
            [postRequest setValue:@"text/xml" forHTTPHeaderField:@"Content-Type"];
            [postRequest setHTTPBody:[NSData dataWithBytes:[postDataStr UTF8String] length:strlen([postDataStr UTF8String])]];
            [[theURLSession dataTaskWithRequest:postRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                if (data.length != 0) {
                    [delegate preferencesUpdated:YES];
                    if ([[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]) {
                        NSUserDefaults *defaults = [[NSUserDefaults standardUserDefaults] init];
                        [defaults setObject:[NSString stringWithFormat:@"%i",weekday] forKey:@"firstDayOfWeek"];
                    }
                } else {
                    [delegate preferencesUpdated:NO];
                }
            }] resume];
        } else {
            [delegate preferencesUpdated:NO];
        }
    }] resume];
}

-(void)getShoeXMLForAccount:(NSDictionary*)keychainDictionary {
    keychainDictionaryForWatch = [NSMutableDictionary dictionaryWithDictionary:keychainDictionary];
    defaultShoeFound = false;
    NSURLRequest *theRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.logarun.com/xml.ashx?type=options"] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:5];
    [[theURLSession dataTaskWithRequest:theRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data.length != 0) {
            NSXMLParser *newParser = [[NSXMLParser alloc] initWithData:data];
            newParser.delegate = self;
            newParser.shouldProcessNamespaces = NO;
            [newParser parse];
        } else {
//            either the user's sqlAuthId was deleted from server after one year, or there is no connection
//            try to load homepage to see if user is logged in
            NSURLRequest *homePageRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.logarun.com"] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:2];
            [[theURLSession dataTaskWithRequest:homePageRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                if (data.length != 0) {
                    NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    if ([dataString containsString:@"<a title=\"Sign up for a new LogARun.com account.\" href=\"signup.aspx\">Signup</a>"]) {
                        // user must be logged out and logged in again
                        [self logout];
                        [self.delegate sqlAuthIdDeleted];
                    } else {
                        // the show xml did not load after 5 seconds, but the home page did and everything else is working
                        // try loading the show xml again?
                        [self.delegate sessionDidLogin:0];
                    }
                } else {
                    // there is truly no connection
                    [self.delegate sessionDidLogin:0];
                }
            }] resume];
        }
    }] resume];
}

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary<NSString *,NSString *> *)attributeDict {
    if ([elementName isEqualToString:@"shoe"] && [[attributeDict objectForKey:@"retired"] isEqualToString:@"0"]) {
        _shoeDictionary[[attributeDict objectForKey:@"id"]] = [attributeDict objectForKey:@"name"];
        if ([[attributeDict objectForKey:@"default"] isEqualToString:@"1"]) {
            [keychainDictionaryForWatch setObject:[attributeDict objectForKey:@"id"] forKey:@"shoe"];
            defaultShoeFound = true;
        }
    } else if ([elementName isEqualToString:@"options"]) {
        // save the first day of the week to user defaults
        NSUserDefaults *defaults = [[NSUserDefaults standardUserDefaults] init];
        // monday is 1
        // sunday is 0
        NSLog(@"first day of week xml value:%@",[attributeDict objectForKey:@"firstDayOfWeek"]);
        [defaults setObject:[attributeDict objectForKey:@"firstDayOfWeek"] forKey:@"firstDayOfWeek"];
        [keychainDictionaryForWatch setObject:[attributeDict objectForKey:@"firstDayOfWeek"] forKey:@"firstDayOfWeek"];
    }
}

-(void)parserDidEndDocument:(NSXMLParser *)parser {
    //send keychain to watch
    if (!defaultShoeFound) {
        [keychainDictionaryForWatch setObject:@"none" forKey:@"shoe"];
    }
    [self updateWatchApp];
    [self.delegate sessionDidLogin:1];
}

-(void)getRunForDate:(NSDate*)date delegate:(id)delegate{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM/dd/yyyy"];
    NSString *urlFormattedDateString = [dateFormatter stringFromDate:date];

    NSURLRequest *theRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.logarun.com/edit.aspx?username=%@&date=%@",username,urlFormattedDateString]] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:45];
    
    NSURLSessionDataTask *currentGetRunTask = [theURLSession dataTaskWithRequest:theRequest completionHandler:^(NSData *data,
                                                             NSURLResponse *response,
                                                             NSError *error) {
        NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (dataString.length != 0) {
            LARRun *theRun = [[LARRun alloc] init];
            //get eventValidation and viewState
            NSRange viewStateResultRange = [dataString rangeOfString:@"\"__VIEWSTATE\" value=\""];
            NSRange viewEndResultRange = [dataString rangeOfString:@"script src=\"yui/2.6.0/build/yahoo-dom-event"];
            if (viewStateResultRange.location != NSNotFound && viewEndResultRange.location != NSNotFound) {
                theRun.viewState = [dataString substringWithRange:NSMakeRange(viewStateResultRange.location+viewStateResultRange.length,viewEndResultRange.location-viewStateResultRange.location-viewStateResultRange.length-11)];
            }
            NSRange eventValidationResultRange = [dataString rangeOfString:@"EVENTVALIDATION\" value=\""];
            theRun.eventValidation = [dataString substringFromIndex:eventValidationResultRange.location+eventValidationResultRange.length];
            NSRange validationEndResultRange = [theRun.eventValidation rangeOfString:@"\" />"];
            theRun.eventValidation = [theRun.eventValidation substringToIndex:validationEndResultRange.location];
            
            theRun.dayTitle = [self getValueForId:@"ctl00_Content_c_dayTitle_c_title" inDataString:dataString];
            theRun.dayTitle = [theRun.dayTitle stringByDecodingHTMLEntities];
            NSRange noteInnerHTMLRange = [dataString rangeOfString:[self getInnerHTMLForId:@"ctl00_Content_c_note_c_note" inDataString:dataString]];
            theRun.note = [dataString substringWithRange:NSMakeRange(noteInnerHTMLRange.location + 2, noteInnerHTMLRange.length - 2)];
            theRun.note = [theRun.note stringByDecodingHTMLEntities];
            
            // deprecated
            //theRun.distance = [self getValueForId:@"ctl00_Content_c_applications_act1_ctl00_c_decimal" inDataString:dataString];
            //theRun.duration = [self getValueForId:@"ctl00_Content_c_applications_act1_ctl02_c_duration" inDataString:dataString];
            
            // get all runs, not just the first one
            int act = 1;
            NSMutableArray *distances = [[NSMutableArray alloc] init];
            NSMutableArray *durations = [[NSMutableArray alloc] init];
            NSString *nextDistance = [self getValueForId:[NSString stringWithFormat:@"ctl00_Content_c_applications_act%d_ctl00_c_decimal",act] inDataString:dataString];
            NSString *nextDuration = [self getValueForId:[NSString stringWithFormat:@"ctl00_Content_c_applications_act%d_ctl02_c_duration",act] inDataString:dataString];
            while (![nextDistance isEqualToString:@""]) {
                [distances addObject:nextDistance];
                [durations addObject:nextDuration];
                act++;
                nextDistance = [self getValueForId:[NSString stringWithFormat:@"ctl00_Content_c_applications_act%d_ctl00_c_decimal",act] inDataString:dataString];
                nextDuration = [self getValueForId:[NSString stringWithFormat:@"ctl00_Content_c_applications_act%d_ctl02_c_duration",act] inDataString:dataString];
            }
            theRun.distances = distances;
            theRun.durations = durations;
            
            theRun.weight = [self getValueForId:@"ctl00_Content_c_applications_act0_ctl00_c_decimal" inDataString:dataString];
            theRun.sleepHours = [self getValueForId:@"ctl00_Content_c_applications_act0_ctl02_c_decimal" inDataString:dataString];
            theRun.morningPulse = [self getValueForId:@"ctl00_Content_c_applications_act0_ctl01_c_decimal" inDataString:dataString];
            theRun.averageHeartRate = [self getValueForId:@"ctl00_Content_c_applications_act1_ctl06_c_decimal" inDataString:dataString];
            theRun.percentBodyFat = [self getValueForId:@"ctl00_Content_c_applications_act0_ctl03_c_decimal" inDataString:dataString];
            
            NSRange shoeValueStart = [dataString rangeOfString:[NSString stringWithFormat:@"selected=\"selected\""]];
            if (shoeValueStart.location == NSNotFound) {
                theRun.shoeKey = @"";
            } else {
                shoeValueStart.location += shoeValueStart.length + 8;
                NSRange shoeValueEnd = [dataString rangeOfString:@"\"" options:NSLiteralSearch range:NSMakeRange(shoeValueStart.location, dataString.length-shoeValueStart.location)];
                theRun.shoeKey = [dataString substringWithRange:NSMakeRange(shoeValueStart.location, shoeValueEnd.location-shoeValueStart.location)];
            }
            
            // check if user is brand new or never posted multiple runs before
            NSUserDefaults *defaults = [[NSUserDefaults standardUserDefaults] init];
            if ([[self getValueForId:@"ctl00_Content_c_applications_ctl00_Content_c_applications_ctl02" inDataString:dataString] isEqualToString:@"Run"]) {
                [defaults setBool:NO forKey:@"newUser"];
            } else {
                [defaults setBool:YES forKey:@"newUser"];
            }
            [delegate didReceiveRun:theRun forDate:date];
        } else {
            // no connection or canceled
            if (cancelingTasks) {
                [delegate didReceiveRun:nil forDate:nil];
            }
        }
    }];
    [currentGetRunTask resume];
    
}

-(void)postRunOnDate:(NSString *)date dayTitle:(NSString *)title distances:(NSArray<NSString *> *)distances durations:(NSArray<NSString *> *)durations dailyNote:(NSString *)note delegate:(id<LARSessionDelegateProtocol>)delegate shoeKey:(NSString *)shoeKey weight:(NSString *)weight morningPulse:(NSString *)morningPulse sleepHours:(NSString *)sleepHours averageHeartRate:(NSString *)averageHeartRate percentBodyFat:(NSString *)percentBodyFat eventValidation:(NSString *)eventValidation viewState:(NSString *)viewState attempt:(int)attempt {
    
    int attemptsRequired;
    if ([distances count] == 1) {
        attemptsRequired  = 1;
    } else {
        attemptsRequired = 2 + ((int)[distances count] - 2) * 2;
    }
    
    note = [self stringToHex:note];
    title = [self stringToHex:title];
    
    NSUserDefaults *defaults = [[NSUserDefaults standardUserDefaults] init];
    if (attempt < attemptsRequired) {
        if ([defaults boolForKey:@"newUser"]) {
            if (attempt % 2 == 1) {
                NSLog(@"adding scriptmanager odd for new user");
                bodyData = [NSString stringWithFormat:@"ctl00%%24Content%%24c_scriptManager=ctl00%%24Content%%24c_applications%%24c_appUpdatePanel%%7Cctl00%%24Content%%24c_applications%%24ctl00_Content_c_applications_ctl54&__EVENTTARGET=ctl00%%24Content%%24c_applications%%24ctl00_Content_c_applications_ctl54&"];
            } else {
                NSLog(@"adding scriptmanager even for new user");
                bodyData = [NSString stringWithFormat:@"ctl00%%24Content%%24c_scriptManager=ctl00%%24Content%%24c_applications%%24c_appUpdatePanel%%7Cctl00%%24Content%%24c_applications%%24ctl00_Content_c_applications_ctl134&__EVENTTARGET=ctl00%%24Content%%24c_applications%%24ctl00_Content_c_applications_ctl134&"];
            }
        } else {
            if (attempt % 2 == 1) {
                NSLog(@"adding scriptmanager odd");
                bodyData = [NSString stringWithFormat:@"ctl00%%24Content%%24c_scriptManager=ctl00%%24Content%%24c_applications%%24c_appUpdatePanel%%7Cctl00%%24Content%%24c_applications%%24ctl00_Content_c_applications_ctl02&__EVENTTARGET=ctl00%%24Content%%24c_applications%%24ctl00_Content_c_applications_ctl02&"];
            } else {
                NSLog(@"adding scriptmanager even");
                bodyData = [NSString stringWithFormat:@"ctl00%%24Content%%24c_scriptManager=ctl00%%24Content%%24c_applications%%24c_appUpdatePanel%%7Cctl00%%24Content%%24c_applications%%24ctl00_Content_c_applications_ctl82&__EVENTTARGET=ctl00%%24Content%%24c_applications%%24ctl00_Content_c_applications_ctl82&"];
            }
        }
    } else {
        NSLog(@"last attempt");
        bodyData = @"";
    }
    
    bodyData = [bodyData stringByAppendingString:[NSString stringWithFormat:@"__VIEWSTATE=%@&__EVENTVALIDATION=%@&ctl00%%24Content%%24c_dayTitle%%24c_title=%@&ctl00%%24Content%%24c_applications%%24act0%%24c_collapsedHidden=1&ctl00%%24Content%%24c_applications%%24act0%%24ctl00%%24c_decimal=%@&ctl00%%24Content%%24c_applications%%24act0%%24ctl01%%24c_decimal=%@&ctl00%%24Content%%24c_applications%%24act0%%24ctl02%%24c_decimal=%@&ctl00%%24Content%%24c_applications%%24act0%%24ctl03%%24c_decimal=%@",[self stringToHex:viewState],[self stringToHex:eventValidation],title,weight,morningPulse,sleepHours,percentBodyFat]];

    for (int act = 1; act <= [distances count]; act++) {
        bodyData = [bodyData stringByAppendingString:[NSString stringWithFormat:@"&ctl00%%24Content%%24c_applications%%24act%d%%24c_collapsedHidden=1&ctl00%%24Content%%24c_applications%%24act%d%%24ctl00%%24c_decimal=%@&ctl00%%24Content%%24c_applications%%24act%d%%24ctl02%%24c_duration=%@",act,act,distances[act - 1],act,durations[act - 1]]];
    }
    
    if (![shoeKey isEqualToString:@""]) {
        for (int act = 1; act <= [distances count]; act++) {
            bodyData = [bodyData stringByAppendingString:[NSString stringWithFormat:@"&ctl00%%24Content%%24c_applications%%24act%d%%24ctl04%%24c_dropdown=%@",act,shoeKey]];
        }
    }
    bodyData = [bodyData stringByAppendingString:[NSString stringWithFormat:@"&ctl00%%24Content%%24c_applications%%24act1%%24ctl06%%24c_decimal=%@&ctl00%%24Content%%24c_note%%24c_note=%@",averageHeartRate,note]];

    if (attempt == attemptsRequired) {
        bodyData = [bodyData stringByAppendingString:@"&ctl00%24Content%24c_save=Save"];
    }
    
    NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.logarun.com/Edit.aspx?username=%@&date=%@",username,date]]];
    
    // Set the request's content type to application/x-www-form-urlencoded
    [postRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    // Designate the request a POST request and specify its body data
    [postRequest setHTTPMethod:@"POST"];
    [postRequest setHTTPBody:[NSData dataWithBytes:[bodyData UTF8String] length:strlen([bodyData UTF8String])]];
    if (attempt < attemptsRequired) {
        [postRequest setValue:@"Mozilla/5.0" forHTTPHeaderField:@"User-Agent"];
        [postRequest setValue:@"Delta=true" forHTTPHeaderField:@"X-MicrosoftAjax"];
    }
    [[theURLSession dataTaskWithRequest:postRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"recevied response for attempt:%d of %d",attempt,attemptsRequired);
        if (attempt < attemptsRequired) {
            [self postRunOnDate:date dayTitle:title distances:distances durations:durations dailyNote:note delegate:delegate shoeKey:shoeKey weight:weight morningPulse:morningPulse sleepHours:sleepHours averageHeartRate:averageHeartRate percentBodyFat:percentBodyFat eventValidation:[self getAbsValueForID:@"__EVENTVALIDATION" inDataString:dataString] viewState:[self getAbsValueForID:@"__VIEWSTATE" inDataString:dataString] attempt:attempt + 1];
        } else {
            [delegate runPosted];
        }
    }] resume];
}

-(void)getGeneralInfoToDelegate:(id<LARSessionDelegateProtocol>)delegate {
    [[theURLSession dataTaskWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.logarun.com/profile.aspx?username=%@",username]] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data.length != 0) {
            NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSString *tableString = [self getInnerHTMLForId:@"personal" inDataString:dataString];
            
            NSMutableArray *rowArray = [[NSMutableArray alloc] init];
            NSRange rowStartRange = [tableString rangeOfString:@"<tr>"];
            while (rowStartRange.location != NSNotFound) {
                NSRange rowEndRange = [tableString rangeOfString:@"</tr>" options:NSLiteralSearch range:NSMakeRange(rowStartRange.location, tableString.length - rowStartRange.location)];
                [rowArray addObject:[tableString substringWithRange:NSMakeRange(rowStartRange.location + rowStartRange.length, rowEndRange.location - rowStartRange.location - rowStartRange.length)]];
                rowStartRange = [tableString rangeOfString:@"<tr>" options:NSLiteralSearch range:NSMakeRange(rowEndRange.location, tableString.length - rowEndRange.location)];
            }
            NSMutableDictionary *generalInfoDictionary = [[NSMutableDictionary alloc] init];
            for (NSString *row in rowArray) {
                NSRange keyEndRange = [row rangeOfString:@"</th>"];
                [generalInfoDictionary setObject:[row substringWithRange:NSMakeRange(keyEndRange.location + 9, row.length - keyEndRange.location - 14)] forKey:[row substringWithRange:NSMakeRange(4,keyEndRange.location - 4)]];
            }
            [delegate didReceiveGeneralInfo:generalInfoDictionary];
        } else {
            // request timed out
            [delegate didReceiveGeneralInfo:nil];
        }
    }] resume];
    
}

-(void)getShoeXMLStringToDelegate:(id<LARSessionDelegateProtocol>)delegate {
    [[theURLSession dataTaskWithURL:[NSURL URLWithString:@"http://www.logarun.com/xml.ashx?type=options"] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [delegate didReceiveShoeXML:data];
    }] resume];
}

-(void)getTeamsDictToDelegate:(id<LARSessionDelegateProtocol>)delegate {
    [[theURLSession dataTaskWithURL:[NSURL URLWithString:@"http://www.logarun.com"] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data.length != 0) {
            NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSMutableDictionary *teamDict = [[NSMutableDictionary alloc] init];
            
            NSRange idStartRange = [dataString rangeOfString:@"href=\"TeamCalendar.aspx?teamid="];
            
            while (idStartRange.location != NSNotFound) {
            
                NSRange idEndRange = [dataString rangeOfString:@"\"" options:NSLiteralSearch range:NSMakeRange(idStartRange.location + idStartRange.length, dataString.length - idStartRange.location - idStartRange.length)];
                
                NSRange nameEndRange = [dataString rangeOfString:@"</a>" options:NSLiteralSearch range:NSMakeRange(idStartRange.location, dataString.length - idStartRange.location)];
                
                [teamDict setObject:[dataString substringWithRange:NSMakeRange(idStartRange.location + idStartRange.length,idEndRange.location - idStartRange.location - idStartRange.length)] forKey:[dataString substringWithRange:NSMakeRange(idEndRange.location + 2, nameEndRange.location - idEndRange.location - 2)]];
                idStartRange = [dataString rangeOfString:@"href=\"TeamCalendar.aspx?teamid=" options:NSLiteralSearch range:NSMakeRange(nameEndRange.location, dataString.length - nameEndRange.location)];
            }
            NSLog(@"returning dict:%@",teamDict);
            [delegate didReceiveTeamsDict:teamDict];
        } else {
            [delegate didReceiveTeamsDict:nil];
        }
    }] resume];
}

-(NSArray*)parseHTMLTableIntoArrayWithTag:(NSString*)tagString inTableString:(NSString*)tableString {
    NSMutableArray *rowArray = [[NSMutableArray alloc] init];
    NSString *startTag = [tagString substringToIndex:3];
    NSString *endTag = [NSString stringWithFormat:@"%@/%@",[tagString substringToIndex:1],[tagString substringWithRange:NSMakeRange(1, tagString.length - 1)]];
    NSRange rowStartRange = [tableString rangeOfString:startTag];
    while (rowStartRange.location != NSNotFound) {
        NSRange rowEndRange = [tableString rangeOfString:endTag options:NSLiteralSearch range:NSMakeRange(rowStartRange.location, tableString.length - rowStartRange.location)];
        NSRange rowStartTagEndRange = [tableString rangeOfString:@">" options:NSLiteralSearch range:NSMakeRange(rowStartRange.location + rowStartRange.length, tableString.length - rowStartRange.location - rowStartRange.length)];
        [rowArray addObject:[tableString substringWithRange:NSMakeRange(rowStartTagEndRange.location + 1, rowEndRange.location - rowStartTagEndRange.location - 1)]];
        rowStartRange = [tableString rangeOfString:startTag options:NSLiteralSearch range:NSMakeRange(rowEndRange.location, tableString.length - rowEndRange.location)];
    }
    return rowArray;
}

-(void)getDictionaryOfTeamRunsToDelegate:(id<LARSessionDelegateProtocol>)delegate withID:(NSString *)idNumber withDate:(NSDate *)date{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM-dd-yyyy"];
    NSString *dateString = [dateFormatter stringFromDate:date];
    [[theURLSession dataTaskWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.logarun.com/TeamCalendar.aspx?teamid=%@&date=%@",idNumber,dateString]] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data.length != 0) {
            NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            dataString = [dataString stringByDecodingHTMLEntities];
            NSString *tableString = [self getInnerHTMLForId:@"ctl00_Content_c_calendar_c_monthTbl" inDataString:dataString];
            NSArray *membersArray = [self parseHTMLTableIntoArrayWithTag:@"<tr>" inTableString:tableString];
            NSMutableDictionary *teamRunsDict = [[NSMutableDictionary alloc] init];
            [membersArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                // this block is called for each team member
                NSArray *weekArray = [self parseHTMLTableIntoArrayWithTag:@"<td>" inTableString:obj];
                if (weekArray.count == 9) {
                    NSString *objString = obj;
                    NSString *usernameLink = [self getInnerHTMLForClass:@"day" inDataString:obj withRange:NSMakeRange(0, objString.length)];
                    NSRange userStartRange = [usernameLink rangeOfString:@">"];
                    NSRange userEndRange = [usernameLink rangeOfString:@"<" options:NSLiteralSearch range:NSMakeRange(userStartRange.location, usernameLink.length - userStartRange.location)];
                    NSString *teamMember = [usernameLink substringWithRange:NSMakeRange(userStartRange.location + 1, userEndRange.location - userStartRange.location - 1)];
                    NSMutableArray *LARRunArray = [[NSMutableArray alloc] init];
                    NSIndexSet *weekDayIndexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 7)];
                    [weekArray enumerateObjectsAtIndexes:weekDayIndexSet options:NSEnumerationConcurrent usingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        // this block is called for each day of the week
                        LARRun *run = [[LARRun alloc] init];
                        NSString *objString = obj;
                        run.dayTitle = [self getInnerHTMLForClass:@"dayTitle" inDataString:obj withRange:NSMakeRange(0, objString.length)];
                        run.commentURL = [self getHREFForClass:@"dayNum" inDataString:objString];
                        NSString *runInfo = [self getInnerHTMLForClass:@"body" inDataString:obj withRange:NSMakeRange(0, objString.length)];
                        // get run distance
                        NSRange mileageStartRange = [runInfo rangeOfString:@"Run: "];
                        if (mileageStartRange.location != NSNotFound) {
                            NSRange mileageEndRange = [runInfo rangeOfString:@"<" options:NSLiteralSearch range:NSMakeRange(mileageStartRange.location, runInfo.length - mileageStartRange.location)];
                            NSString *distance = [runInfo substringWithRange:NSMakeRange(mileageStartRange.location + mileageStartRange.length, mileageEndRange.location - mileageStartRange.location - mileageStartRange.length)];
                            
                            NSMutableArray *runArray = [self getArrayAndTotalFromMultipleRuns:distance];
                            run.totalDistance = [runArray lastObject];
                            [runArray removeLastObject];
                            if ([runArray count] > 0) {
                                run.distances = runArray;
                            }
                        } else {
                            run.totalDistance = @"0.00 mile";
                        }
                        // get run duration
                        NSRange durationStartRange = [runInfo rangeOfString:@"Time: "];
                        if (durationStartRange.location != NSNotFound) {
                            NSRange durationEndRange = [runInfo rangeOfString:@"<" options:NSLiteralSearch range:NSMakeRange(durationStartRange.location, runInfo.length - durationStartRange.location)];
                            NSString *duration = [runInfo substringWithRange:NSMakeRange(durationStartRange.location + durationStartRange.length, durationEndRange.location - durationStartRange.location - durationStartRange.length)];
                            
                            NSMutableArray *runArray = [self getArrayAndTotalFromMultipleRuns:duration];
                            run.totalDuration = [runArray lastObject];
                            [runArray removeLastObject];
                            if ([runArray count] > 0) {
                                run.durations = runArray;
                            }
                        } else {
                            run.totalDuration = @"00:00:00";
                        }
                        // get run paces
                        NSRange paceStartRange = [runInfo rangeOfString:@"br/>Run Pace:"];
                        if (paceStartRange.location != NSNotFound) {
                            NSRange paceEndRange = [runInfo rangeOfString:@"<br/>" options:NSLiteralSearch range:NSMakeRange(paceStartRange.location, runInfo.length - paceStartRange.location)];
                            NSString *runs = [runInfo substringWithRange:NSMakeRange(paceStartRange.location + paceStartRange.length, paceEndRange.location - paceStartRange.location - paceStartRange.length)];
                            NSRange endCommaRange = [runs rangeOfString:@","];
                            NSUInteger startCommaLocation = -1;
                            NSMutableArray *runArray = [[NSMutableArray alloc] init];
                            while (endCommaRange.location != NSNotFound) {
                                [runArray addObject:[runs substringWithRange:NSMakeRange(startCommaLocation + 1, endCommaRange.location - startCommaLocation - 1)]];
                                startCommaLocation = endCommaRange.location + 1;
                                endCommaRange = [runs rangeOfString:@"," options:NSLiteralSearch range:NSMakeRange(startCommaLocation, runs.length - startCommaLocation)];
                            }
                            [runArray addObject:[runs substringWithRange:NSMakeRange(startCommaLocation + 1, runs.length - startCommaLocation - 1)]];
                            run.paces = runArray;
                        } else {
                            run.paces = nil;
                        }
                        
                        // get run note
                        NSRange noteStartRange = [runInfo rangeOfString:@"Note</strong>: "];
                        if (noteStartRange.location != NSNotFound) {
                            NSRange noteEndRange = [runInfo rangeOfString:@"<br/>" options:NSLiteralSearch range:NSMakeRange(noteStartRange.location, runInfo.length - noteStartRange.location)];
                            run.note = [runInfo substringWithRange:NSMakeRange(noteStartRange.location + noteStartRange.length, noteEndRange.location - noteStartRange.location - noteStartRange.length)];
                        } else {
                            run.note = @"";
                        }
                        // create comment dictionary
                        NSRange posterRangeStart = [runInfo rangeOfString:@"<strong>["];
                        NSMutableArray *tempCommentsArr;
                        NSMutableArray *tempCommentersArr;
                        if (posterRangeStart.location != NSNotFound) {
                            tempCommentsArr = [[NSMutableArray alloc] init];
                            tempCommentersArr = [[NSMutableArray alloc] init];
                        }
                        while (posterRangeStart.location != NSNotFound) {
                            NSRange posterRangeEnd = [runInfo rangeOfString:@"]<" options:NSLiteralSearch range:NSMakeRange(posterRangeStart.location, runInfo.length - posterRangeStart.location)];
                            NSString *poster = [runInfo substringWithRange:NSMakeRange(posterRangeStart.location + posterRangeStart.length, posterRangeEnd.location - posterRangeStart.location - posterRangeStart.length)];
                            [tempCommentersArr addObject:poster];
                            NSRange postEndRange = [runInfo rangeOfString:@"<br/>" options:NSLiteralSearch range:NSMakeRange(posterRangeEnd.location, runInfo.length - posterRangeEnd.location)];
                            NSString *post = [runInfo substringWithRange:NSMakeRange(posterRangeEnd.location + 11, postEndRange.location - posterRangeEnd.location - 11)];
                            [tempCommentsArr addObject:post];
                            
                            posterRangeStart = [runInfo rangeOfString:@"<strong>[" options:NSLiteralSearch range:NSMakeRange(postEndRange.location, runInfo.length - postEndRange.location)];
                        }
                        run.commentersArr = tempCommentersArr;
                        run.commentsArr = tempCommentsArr;
                        
                        [LARRunArray addObject:run];
                    }];
                    [teamRunsDict setObject:LARRunArray forKey:teamMember];
                }
            }];
            [delegate didReceiveTeamRunsDict:teamRunsDict withDate:date];
        } else {
            // connection timed out or no wifi
            [delegate didReceiveTeamRunsDict:nil withDate:date];
        }
    }] resume];
}

-(void)cancelGetRunTasks {
    cancelingTasks = true;
    [theURLSession getAllTasksWithCompletionHandler:^(NSArray<__kindof NSURLSessionTask *> * _Nonnull tasks) {
        [tasks enumerateObjectsUsingBlock:^(__kindof NSURLSessionTask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj cancel];
        }];
        cancelingTasks = false;
    }];
}

-(void)postComment:(NSString *)comment onRun:(LARRun *)run delegate:(id<LARSessionDelegateProtocol>)delegate{
    // request view page to find viewstate and eventvalidation, and then post comment and notify delegate
    NSURLRequest *theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.logarun.com/%@",run.commentURL]] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:7];
    [[theURLSession dataTaskWithRequest:theRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (data.length != 0) {
            NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            if ([dataString rangeOfString:@"ctl00_Content_c_comments_c_note"].location != NSNotFound) {
                // permission to comment granted
                NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.logarun.com/%@",run.commentURL]]];
                NSString *postData = [NSString stringWithFormat:@"__VIEWSTATE=%@&__EVENTVALIDATION=%@&ctl00%%24Content%%24c_comments%%24c_note=%@&ctl00%%24Content%%24c_comments%%24c_save=Save",[self getValueForId:@"__VIEWSTATE" inDataString:dataString],[self getValueForId:@"__EVENTVALIDATION" inDataString:dataString],comment];
                [postRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
                [postRequest setHTTPMethod:@"POST"];
                [postRequest setHTTPBody:[NSData dataWithBytes:[postData UTF8String] length:strlen([postData UTF8String])]];
                [[theURLSession dataTaskWithRequest:postRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                    if (data.length == 0) {
                        [delegate commentPostedWithStatus:CommentPostConnectionFailed];
                    } else {
                        [delegate commentPostedWithStatus:CommentPostSucceeded];
                    }
                }] resume];
            } else {
                // permission denied
                [delegate commentPostedWithStatus:CommentPostPermissionDenied];
            }
        } else {
            [delegate commentPostedWithStatus:CommentPostConnectionFailed];
        }
    }] resume];
}

-(NSString *)getUsername {
    return username;
}

#pragma mark - apple watch methods

-(void)sendWatchTitles:(NSArray*)titlesArr andNotes:(NSArray*)notesArr {
    if (self.watchSession) {
        NSError *error = nil;
        NSMutableDictionary *presetsDict = [[NSMutableDictionary alloc] init];
        [presetsDict setObject:@"update-presets" forKey:@"action"];
        [presetsDict setObject:titlesArr forKey:@"titles"];
        [presetsDict setObject:notesArr forKey:@"notes"];
        if(![self.watchSession
             updateApplicationContext:presetsDict error:&error]){
            NSLog(@"sending titles and notes failed with error: %@", error.localizedDescription);
        } else {
            NSLog(@"sending watch titles:%@ and notes: %@",titlesArr,notesArr);
        }
    }
}

-(void)sendWatchMileageGoal:(NSString*)goal {
    if(self.watchSession) {
        NSError *error = nil;
        NSLog(@"sending watch mileage goal");
        NSMutableDictionary *contextDict = [[NSMutableDictionary alloc] init];
        [contextDict setObject:@"mileage-goal" forKey:@"action"];
        [contextDict setObject:goal forKey:@"goal"];
        if(![self.watchSession
             updateApplicationContext:contextDict error:&error]){
            NSLog(@"telling watch to logout failed with error: %@", error.localizedDescription);
        }
    }
}

-(void)sendWatchHealthDefault:(BOOL)submitHealthData {
    if (self.watchSession) {
        NSError *error = nil;
        NSMutableDictionary *presetsDict = [[NSMutableDictionary alloc] init];
        [presetsDict setObject:@"health-default" forKey:@"action"];
        NSNumber *boolNumber = [NSNumber numberWithBool:submitHealthData];
        [presetsDict setObject:boolNumber forKey:@"submit-data"];
        if(![self.watchSession
             updateApplicationContext:presetsDict error:&error]){
            NSLog(@"sending health default failed with error: %@", error.localizedDescription);
        }
    }
}

-(void)logout {
    //clear cookies
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *each in cookieStorage.cookies) {
        [cookieStorage deleteCookie:each];
    }
    
    //creat search dictionary
    NSMutableDictionary *passwordQueryDictionary = [[NSMutableDictionary alloc] init];
    [passwordQueryDictionary setObject:(__bridge id)kSecClassInternetPassword forKey:(__bridge id)kSecClass];
    [passwordQueryDictionary setObject:@"sqlAuthCookie" forKey:(__bridge id)kSecAttrLabel];
    
    // Then call Keychain Services to delete the keychain
    OSStatus keychainError = noErr;
    keychainError = SecItemDelete((__bridge CFDictionaryRef)passwordQueryDictionary);
    if (keychainError == noErr) {
        if(self.watchSession) {
            NSError *error = nil;
            NSLog(@"telling watch to log out");
            if(![self.watchSession
                 updateApplicationContext:@{ @"logout" : @YES} error:&error]){
                NSLog(@"telling watch to logout failed with error: %@", error.localizedDescription);
            }
        }
    } else {
        NSLog(@"something has gone wrong: %d",(int)keychainError);
    }
}

-(void)updateWatchApp {
    /* So this is a list of all the information that gets sent to the watch
            -just logout of current account:YES/NO
            -all details of current account (including kSec keychain details and default shoe)
            ----submit-data (health data):YES/NO
            ----mileage-goal:NSString
            ----preset titles and notes:NSArray,NSArray
    */
    if (self.watchSession) {
        if (self.watchSession.activationState == WCSessionActivationStateNotActivated) {
            NSLog(@"WCSession was somehow not activated, activating now");
            [self.watchSession activateSession];
        }
        
        NSError *error = nil;
        
        NSUserDefaults *defaults = [[NSUserDefaults standardUserDefaults] init];
        
        // submit-data (health data):YES/NO
        NSNumber *boolNumber = [NSNumber numberWithBool:[defaults boolForKey:@"watch-health"]];
        [keychainDictionaryForWatch setObject:boolNumber forKey:@"submit-data"];
        
        // mileage goal
        [keychainDictionaryForWatch setObject:[NSString stringWithFormat:@"%.2lf",[defaults doubleForKey:@"mileage-goal"]] forKey:@"goal"];
        
        // presets
        [keychainDictionaryForWatch setObject:[defaults objectForKey:@"titles"] forKey:@"titles"];
        [keychainDictionaryForWatch setObject:[defaults objectForKey:@"notes"] forKey:@"notes"];
        
        [keychainDictionaryForWatch setObject:@NO forKey:@"logout"];
        
        NSLog(@"updating watch with context: %@",keychainDictionaryForWatch);
        if(![self.watchSession
             updateApplicationContext:keychainDictionaryForWatch error:&error]){
            NSLog(@"updating watch app with new info failed with error: %@", error.localizedDescription);
        }
    }
}

-(void)session:(WCSession *)session activationDidCompleteWithState:(WCSessionActivationState)activationState error:(NSError *)error {
    NSLog(@"WCSession activation complete with error: %@",error);
}

-(void)sessionDidDeactivate:(WCSession *)session {
    
}

-(void)sessionDidBecomeInactive:(WCSession *)session {
    
}

#pragma mark - HTML Parsing Convenience Methods

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

-(NSString*)getInnerHTMLForClass:(NSString*)theID inDataString:(NSString*)dataString withRange:(NSRange)searchRange {
    NSRange innerHTMLStart = [dataString rangeOfString:[NSString stringWithFormat:@"class=\"%@\"",theID] options:NSLiteralSearch range:searchRange];
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

-(NSString*)getHREFForClass:(NSString*)theID inDataString:(NSString*)dataString{
    NSRange IDStart = [dataString rangeOfString:[NSString stringWithFormat:@"class=\"%@\"",theID]];
    if (IDStart.location == NSNotFound) {
        return @"";
    } else {
        NSRange tagStart = [dataString rangeOfString:@"<" options:NSBackwardsSearch range:NSMakeRange(0,IDStart.location)];
        NSRange tagEnd = [dataString rangeOfString:@">" options:NSLiteralSearch range:NSMakeRange(IDStart.location, dataString.length - IDStart.location)];
        NSRange valueStart = [dataString rangeOfString:@"href=\"" options:NSLiteralSearch range:NSMakeRange(tagStart.location,tagEnd.location - tagStart.location)];
        if (valueStart.location != NSNotFound) {
            NSRange valueEnd = [dataString rangeOfString:@"\"" options:NSLiteralSearch range:NSMakeRange(valueStart.location+valueStart.length, dataString.length-valueStart.location-valueStart.length)];
            NSString *returnString = [dataString substringWithRange:NSMakeRange(valueStart.location+valueStart.length,valueEnd.location - valueStart.location - valueStart.length)];
            return returnString;
        } else {
            return @"";
        }
    }
}

-(NSMutableArray*)getArrayAndTotalFromMultipleRuns:(NSString*)runs {
    NSRange endCommaRange = [runs rangeOfString:@","];
    NSUInteger startCommaLocation = -1;
    
    // the last object of this array is the total distance
    NSMutableArray *runArray = [[NSMutableArray alloc] init];
    
    if (endCommaRange.location != NSNotFound) {
        runArray = [[NSMutableArray alloc] init];
    }
    while (endCommaRange.location != NSNotFound) {
        [runArray addObject:[runs substringWithRange:NSMakeRange(startCommaLocation + 1, endCommaRange.location - startCommaLocation - 1)]];
        startCommaLocation = endCommaRange.location + 1;
        endCommaRange = [runs rangeOfString:@"," options:NSLiteralSearch range:NSMakeRange(startCommaLocation, runs.length - startCommaLocation)];
    }
    NSRange totalStartRange = [runs rangeOfString:@"("];
    if (totalStartRange.location != NSNotFound) {
        [runArray addObject:[runs substringWithRange:NSMakeRange(startCommaLocation + 1, totalStartRange.location - startCommaLocation - 1)]];
        
        // now add the total distance to the end
        [runArray addObject:[runs substringWithRange:NSMakeRange(totalStartRange.location + 1, runs.length - totalStartRange.location - 2)]];
    } else {
        // there was only one run, just add it as the only item in the array
        [runArray addObject:runs];
    }
    return runArray;
}

-(NSString*)getAbsValueForID:(NSString*)theID inDataString:(NSString*)dataString {
    NSRange valueStartRange = [dataString rangeOfString:[NSString stringWithFormat:@"%@|",theID]];
    NSString *returnString = @"";
    if (valueStartRange.location != NSNotFound) {
        valueStartRange.location = valueStartRange.location + valueStartRange.length;
        NSRange valueEndRange = [dataString rangeOfString:@"|" options:NSLiteralSearch range:NSMakeRange(valueStartRange.location, dataString.length - valueStartRange.location)];
        if (valueEndRange.location != NSNotFound) {
            returnString = [dataString substringWithRange:NSMakeRange(valueStartRange.location, valueEndRange.location - valueStartRange.location)];
            NSLog(@"health fix succeeded to find %@",theID);
            returnString = [self stringToHex:returnString];
        } else {
            NSLog(@"health fix failed to find %@",theID);
        }
    } else {
        NSLog(@"health fix failed to find %@",theID);
    }
    return returnString;
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
            if ([theID isEqualToString:@"__EVENTVALIDATION"] || [[theID substringToIndex:11] isEqualToString:@"__VIEWSTATE"]) {
                NSLog(@"string to hex on id:%@",theID);
                returnString = [self stringToHex:returnString];
            }
            return returnString;
        } else {
            return @"";
        }
    }
}


@end
