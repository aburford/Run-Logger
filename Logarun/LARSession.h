//
//  LARSession.h
//  Logarun
//
//  Created by Andrew Burford on 4/28/16.
//  Copyright © 2016 Andrew Burford. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LARRun.h"
#import "LARSessionDelegateProtocol.h"
@import WatchConnectivity;
@protocol LARSessionDelegateProtocol;



@interface LARSession : NSObject <NSURLSessionTaskDelegate, NSXMLParserDelegate, WCSessionDelegate> {
    
}

@property (nonatomic, retain) id<LARSessionDelegateProtocol> delegate;
@property (copy) NSString *username;
@property (copy) NSMutableDictionary *shoeDictionary;
@property (nonatomic) WCSession *watchSession;

-(NSString*)getUsername;

#pragma XMLStuff
-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary<NSString *,NSString *> *)attributeDict;
-(void)parserDidEndDocument:(NSXMLParser *)parser;

#pragma Main Methods
-(void)loginWithUsername:(NSString *)user password:(NSString *)pass delegate:(id<LARSessionDelegateProtocol>)sender;
-(void)loginWithUsername:(NSString *)user sqlAuth:(NSString *)sqlAuth delegate:(id <LARSessionDelegateProtocol>)delegate;
    
-(void)postRunOnDate:(NSString *)date dayTitle:(NSString *)title distances:(NSArray<NSString *>*)distances durations:(NSArray<NSString *>*)durations dailyNote:(NSString *)note delegate:(id<LARSessionDelegateProtocol>)delegate shoeKey:(NSString *)shoeKey weight:(NSString*)weight morningPulse:(NSString*)morningPulse sleepHours:(NSString*)sleepHours averageHeartRate:(NSString*)averageHeartRate percentBodyFat:(NSString*)percentBodyFat eventValidation:(NSString*)eventValidation viewState:(NSString*)viewState attempt:(int)attempt;

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest *))completionHandler;
-(void)getCurrentMileageToDelegate:(id<LARSessionDelegateProtocol>)delegate;
-(void)getRunForDate:(NSDate*)date delegate:(id<LARSessionDelegateProtocol>)delegate;
-(void)getGeneralInfoToDelegate:(id<LARSessionDelegateProtocol>)delegate;
-(void)getCommentsPermissionsToDelegate:(id<LARSessionDelegateProtocol>)delegate;
-(void)postCommentReadPermission:(int)read writePermission:(int)write dayOfWeek:(int)weekday delegate:(id<LARSessionDelegateProtocol>)delegate;
-(void)getShoeXMLStringToDelegate:(id<LARSessionDelegateProtocol>)delegate;
-(void)getTeamsDictToDelegate:(id<LARSessionDelegateProtocol>)delegate;
-(void)getDictionaryOfTeamRunsToDelegate:(id<LARSessionDelegateProtocol>)delegate withID:(NSString*)idNumber withDate:(NSDate*)date;
-(void)cancelGetRunTasks;
-(void)createAccountWithUsername:(NSString*)user displayName:(NSString*)displayName email:(NSString*)email password:(NSString*)password private:(BOOL)private gender:(NSString*)gender delegate:(id<LARSessionDelegateProtocol>)delegate;
-(void)postComment:(NSString*)comment onRun:(LARRun*)run delegate:(id<LARSessionDelegateProtocol>)delegate;
#pragma mark - apple watch stuff

//-(void)sendWatchTitles:(NSArray*)titlesArr andNotes:(NSArray*)notesArr;
//-(void)sendWatchHealthDefault:(BOOL)submitHealthData;
//-(void)sendWatchMileageGoal:(NSString*)goal;
-(void)logout;
-(void)updateWatchApp;
-(void)session:(WCSession *)session activationDidCompleteWithState:(WCSessionActivationState)activationState error:(NSError *)error;
-(void)sessionDidBecomeInactive:(WCSession *)session;
-(void)sessionDidDeactivate:(WCSession *)session;

@end






