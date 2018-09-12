//
//  LARSession.m
//  Logarun
//
//  Created by Andrew Burford on 4/28/16.
//  Copyright © 2016 Andrew Burford. All rights reserved.
//

#import "LARWatchSession.h"
#import "InterfaceController.h"
@implementation LARWatchSession {
    NSString *bodyData;
    NSURLSession *theURLSession;
}
@synthesize username;

- (NSString *) stringToHex:(NSString *)str
{
    NSUInteger len = [str length];
    unichar *chars = malloc(len * sizeof(unichar));
    [str getCharacters:chars];
    
    NSMutableString *hexString = [[NSMutableString alloc] init];
    
    for(NSUInteger i = 0; i < len; i++ )
    {
        if ([[NSString stringWithFormat:@"%x", chars[i]] isEqual:@"3d"] || [[NSString stringWithFormat:@"%x", chars[i]] isEqual:@"2b"] || [[NSString stringWithFormat:@"%x", chars[i]] isEqual:@"2f"]) {
            [hexString appendString:[NSString stringWithFormat:@"%%%x", chars[i]]];
        } else {
            [hexString appendString:[str substringWithRange:NSMakeRange(i,1)]];
            
        }
    }
    free(chars);
    
    return hexString;
}

-(void)getCurrentMileage {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy/MM"];
    NSDate *today = [NSDate date];
    NSString *formattedDateString = [dateFormatter stringFromDate:today];
    
    NSURLRequest *theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.logarun.com/calendars/%@/%@",username,formattedDateString]] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
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
                                                  NSLog(@"begin parse currentmileage from string of length %d and content: %@",dataString.length,dataString);
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
                                                  [dateFormatter setDateFormat:@"LL/dd\""];
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
                                                              [self.theViewController didReceiveMileage:mileage userAlreadyRan:false];
                                                          } else {
                                                              // there is other input
                                                              NSLog(@"other input found");
                                                              [self.theViewController didReceiveMileage:mileage userAlreadyRan:true];
                                                          }
                                                      } else {
                                                          // daily note is not blank
                                                          NSLog(@"daily note found");
                                                          [self.theViewController didReceiveMileage:mileage userAlreadyRan:true];
                                                      }
                                                  } else {
                                                      // day title is not blank
                                                      NSLog(@"day title found");
                                                      [self.theViewController didReceiveMileage:mileage userAlreadyRan:true];
                                                  }
                                                  
                                        NSLog(@"end parse currentmileage");
                               }] resume];
                               
                           } else {
                               NSLog(@"begin parse currentmileage from string of length %d",dataString.length);
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
                               [dateFormatter setDateFormat:@"LL/dd\""];
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
                                           [self.theViewController didReceiveMileage:mileage userAlreadyRan:false];
                                       } else {
                                           // there is other input
                                           NSLog(@"other input found");
                                           [self.theViewController didReceiveMileage:mileage userAlreadyRan:true];
                                       }
                                   } else {
                                       // daily note is not blank
                                       NSLog(@"daily note found");
                                       [self.theViewController didReceiveMileage:mileage userAlreadyRan:true];
                                   }
                               } else {
                                   // day title is not blank
                                   NSLog(@"day title found");
                                   [self.theViewController didReceiveMileage:mileage userAlreadyRan:true];
                               }
                               
                               NSLog(@"end parse currentmileage");
                           }
                       } else {
                           // connection timed out/failed
                           [self.theViewController didReceiveMileage:-1 userAlreadyRan:YES];
                       }
                   }] resume];
    
    
}

-(void)loginWithUsername:(NSString *)user password:(NSString *)pass delegate:(id <LARSessionDelegateProtocol>)sender {
    username = user;
    self.theViewController = sender;
    // In body data for the 'application/x-www-form-urlencoded' content type,
    // form fields are separated by an ampersand. Note the absence of a
    // leading ampersand.
    bodyData = [NSString stringWithFormat:@"SubmitLogon=true&LoginName=%@&Password=%@&LoginNow=Login",username,pass];
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
                /*
                NSHTTPURLResponse *httpResp = (NSHTTPURLResponse*) response;
                NSArray *cookies = [NSHTTPCookie cookiesWithResponseHeaderFields:[httpResp allHeaderFields] forURL:[response URL]];
                [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookies:cookies forURL:[response URL] mainDocumentURL:nil];
                if ([response.URL isEqual:[NSURL URLWithString:@"http://www.logarun.com/"]]) {
                    // NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
                    NSLog(@"%@",httpResponse);
                    [self.theViewController sessionDidLogin:1];
                } else {
                    [self.theViewController sessionDidLogin:0];
                }
                */
            }] resume];
    theURLSession=session;
}

-(void)loginWithUsername:(NSString *)user sqlAuth:(NSString *)sqlAuth shoe:(NSString* _Nullable)shoe delegate:(id <LARSessionDelegateProtocol>)delegate {
    username = user;
    self.shoeID = shoe;
    self.theViewController = delegate;
    NSDictionary *cookieProperties = [NSDictionary dictionaryWithObjectsAndKeys:sqlAuth,NSHTTPCookieValue,@"sqlAuthCookie",NSHTTPCookieName,@"/",NSHTTPCookiePath,[NSURL URLWithString:@"http://www.logarun.com"],NSHTTPCookieOriginURL, nil];
    NSHTTPCookie *sqlAuthCookie = [NSHTTPCookie cookieWithProperties:cookieProperties];
    NSArray *cookiesArray = [NSArray arrayWithObjects:sqlAuthCookie, nil];
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookies:cookiesArray forURL:[NSURL URLWithString:@"http://www.logarun.com"] mainDocumentURL:nil];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
    theURLSession=session;
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest *))completionHandler {
    if (response.statusCode == 302) {
        NSArray *cookies = [NSHTTPCookie cookiesWithResponseHeaderFields:[response allHeaderFields] forURL:[response URL]];
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookies:cookies forURL:[response URL] mainDocumentURL:nil];
        [self.theViewController sessionDidLogin:1];
    } else {
        [self.theViewController sessionDidLogin:0];
    }
    completionHandler(request);
}

-(void)postRunOnDate:(NSString *)date dayTitle:(NSString *)title distance:(NSString *)distance duration:(NSString *)duration dailyNote:(NSString *)note weight:(NSString *)weight percentBodyFat:(NSString *)percentBodyFat {
    
    NSURLRequest *theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.logarun.com/Edit.aspx?username=%@&date=%@",username,date]] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    NSLog(@"postRun was called, getting viewstate/eventvalidation with url request: %@",[NSString stringWithFormat:@"http://www.logarun.com/Edit.aspx?username=%@&date=%@",username,date]);
    [[theURLSession dataTaskWithRequest:theRequest
                completionHandler:^(NSData *data,
                                    NSURLResponse *response,
                                    NSError *error) {
         if ([data length] > 0 && error == nil)
         {
             
             NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
             NSRange viewStateResultRange = [dataString rangeOfString:@"\"__VIEWSTATE\" value=\""];
             NSRange viewEndResultRange = [dataString rangeOfString:@"script src=\"yui/2.6.0/build/yahoo-dom-event"];
             NSString *viewState = @"errors";
             if (viewStateResultRange.location != NSNotFound && viewEndResultRange.location != NSNotFound) {
                 viewState = [dataString substringWithRange:NSMakeRange(viewStateResultRange.location+viewStateResultRange.length,viewEndResultRange.location-viewStateResultRange.location-viewStateResultRange.length-11)];
             }
             
             NSRange eventValidationResultRange = [dataString rangeOfString:@"EVENTVALIDATION\" value=\""];
             NSString *eventValidation = [dataString substringFromIndex:eventValidationResultRange.location+eventValidationResultRange.length];
             NSRange validationEndResultRange = [eventValidation rangeOfString:@"\" />"];
             eventValidation = [eventValidation substringToIndex:validationEndResultRange.location];
             
             [dataString rangeOfString:@"option"];
             
             
             // In body data for the 'application/x-www-form-urlencoded' content type,
             // form fields are separated by an ampersand. Note the absence of a
             // leading ampersand.
             if ([_shoeID isEqualToString:@"none"]) {
                 bodyData = [NSString stringWithFormat:@"__VIEWSTATE=%@&__EVENTVALIDATION=%@&ctl00%%24Content%%24c_dayTitle%%24c_title=%@&ctl00%%24Content%%24c_applications%%24act0%%24ctl00%%24c_decimal=%@&ctl00%%24Content%%24c_applications%%24act0%%24ctl03%%24c_decimal=%@&ctl00%%24Content%%24c_applications%%24act1%%24ctl00%%24c_decimal=%@&ctl00%%24Content%%24c_applications%%24act1%%24ctl02%%24c_duration=%@&ctl00%%24Content%%24c_note%%24c_note=%@&ctl00%%24Content%%24c_save=Save",[self stringToHex:viewState],[self stringToHex:eventValidation],title,weight,percentBodyFat,distance,duration,note];
             } else {
                 bodyData = [NSString stringWithFormat:@"__VIEWSTATE=%@&__EVENTVALIDATION=%@&ctl00%%24Content%%24c_dayTitle%%24c_title=%@&ctl00%%24Content%%24c_applications%%24act0%%24ctl00%%24c_decimal=%@&ctl00%%24Content%%24c_applications%%24act0%%24ctl03%%24c_decimal=%@&ctl00%%24Content%%24c_applications%%24act1%%24ctl00%%24c_decimal=%@&ctl00%%24Content%%24c_applications%%24act1%%24ctl02%%24c_duration=%@&ctl00%%24Content%%24c_applications%%24act1%%24ctl04%%24c_dropdown=%@&ctl00%%24Content%%24c_note%%24c_note=%@&ctl00%%24Content%%24c_save=Save",[self stringToHex:viewState],[self stringToHex:eventValidation],title,weight,percentBodyFat,distance,duration,_shoeID,note];
             }
             NSLog(@"bodyData for run post request: %@",bodyData);
             NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.logarun.com/Edit.aspx?username=%@&date=%@",username,date]]];
             
             // Set the request's content type to application/x-www-form-urlencoded
             [postRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
             
             // Designate the request a POST request and specify its body data
             [postRequest setHTTPMethod:@"POST"];
             [postRequest setHTTPBody:[NSData dataWithBytes:[bodyData UTF8String] length:strlen([bodyData UTF8String])]];
             NSURLSession *session = [NSURLSession sharedSession];
             [[session dataTaskWithRequest:postRequest
                         completionHandler:^(NSData *data,
                                             NSURLResponse *response,
                                             NSError *error) {
                             // check if post was successful
                             
                             
                             
                             // or don't bother, i dont really care
                         }] resume];
	
         } else {
             // request failed
             [self.theViewController runPostFailed];
         }
         
     }] resume];
    
}

#pragma mark - Convenience methods

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

@end
