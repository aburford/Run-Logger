//
//  LARInitialInterfaceController.h
//  Logarun
//
//  Created by Andrew Burford on 5/29/16.
//  Copyright © 2016 Andrew Burford. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>
#import "LARWatchSession.h"
#import "InterfaceController.h"
@import WatchConnectivity;
@import Security;

@interface LARInitialInterfaceController : WKInterfaceController <WCSessionDelegate>

@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *loginLabel;
@property (nonatomic) WCSession *watchSession;

-(void)mainViewInstance:(InterfaceController*)theInterfaceController;

@end
