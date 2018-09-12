//
//  TeamMemberView.h
//  Logarun
//
//  Created by Andrew Burford on 6/22/16.
//  Copyright © 2016 Andrew Burford. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LARRun.h"
#import "TeamCalTableViewController.h"

@interface TeamMemberView : UIViewController


-(instancetype)initWithFrame:(CGRect)frame;
-(void)setName:(NSString*)name;
-(void)setLARRun:(LARRun*)theRun;
-(NSString*)getName;
-(LARRun*)getRun;
-(void)setTableView:(UITableViewController*)newTableView;
//-(void)repositionElements;

@end
