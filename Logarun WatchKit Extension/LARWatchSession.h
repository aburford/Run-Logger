//
//  LARSession.h
//  Logarun
//
//  Created by Andrew Burford on 4/28/16.
//  Copyright © 2016 Andrew Burford. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LARSessionDelegateProtocol.h"

@class InterfaceController;
@interface LARWatchSession : NSObject <NSURLSessionTaskDelegate> {
    
}
@property (nonatomic, retain) id <LARSessionDelegateProtocol> theViewController;
@property (copy) NSString *username;
@property (copy) NSString *shoeID;

-(void)loginWithUsername:(NSString *)user sqlAuth:(NSString *)sqlAuth shoe:(NSString*)shoe delegate:(id <LARSessionDelegateProtocol>)sender;
-(void)loginWithUsername:(NSString *)user password:(NSString *)pass delegate:(id <LARSessionDelegateProtocol>)sender;
-(void)postRunOnDate:(NSString *)date dayTitle:(NSString *)title distance:(NSString *)distance duration:(NSString *)duration dailyNote:(NSString *)note weight:(NSString *)weight percentBodyFat:(NSString *)percentBodyFat;
- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest *))completionHandler;
-(void)getCurrentMileage;

@end





