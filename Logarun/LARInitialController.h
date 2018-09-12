//
//  LARInitialController.h
//  Logarun
//
//  Created by Andrew Burford on 5/28/16.
//  Copyright © 2016 Andrew Burford. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "TabBarController.h"
#import "LARSession.h"
#import "LARSessionDelegateProtocol.h"

@interface LARInitialController : UIViewController <LARSessionDelegateProtocol>

-(void)viewDidLoad;
-(void)sessionDidLogin:(bool)success;
-(void)sqlAuthIdDeleted;

@end
