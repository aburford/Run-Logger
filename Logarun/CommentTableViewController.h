//
//  CommentTableViewController.h
//  Run Logger
//
//  Created by Andrew Burford on 9/26/16.
//  Copyright © 2016 Andrew Burford. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LARRun.h"
#import "LARSessionDelegateProtocol.h"

@interface CommentTableViewController : UITableViewController <LARSessionDelegateProtocol>

-(void)setLARRun:(LARRun*)newRun andName:(NSString*)newName;
-(void)commentPostedWithStatus:(CommentPostStatus)status;


@end
