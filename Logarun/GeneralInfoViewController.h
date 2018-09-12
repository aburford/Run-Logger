//
//  GeneralInfoViewController.h
//  Logarun
//
//  Created by Andrew Burford on 6/17/16.
//  Copyright © 2016 Andrew Burford. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TabBarController.h"
#import "LARSession.h"


@interface GeneralInfoViewController : UIViewController <LARSessionDelegateProtocol>

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

-(void)didReceiveGeneralInfo:(NSMutableDictionary *)infoDictionary;

@end
