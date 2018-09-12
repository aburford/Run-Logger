//
//  PreferencesViewController.h
//  Run Logger
//
//  Created by Andrew Burford on 10/2/16.
//  Copyright © 2016 Andrew Burford. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TabBarController.h"
#import "LARSession.h"

@interface PreferencesViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate,LARSessionDelegateProtocol>

-(void)preferencesUpdated:(BOOL)success;

@end
