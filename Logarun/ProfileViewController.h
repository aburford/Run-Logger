//
//  ProfileViewController.h
//  Logarun
//
//  Created by Andrew Burford on 5/12/16.
//  Copyright © 2016 Andrew Burford. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TabBarController.h"

@interface ProfileViewController : UITableViewController <UITableViewDelegate,UITableViewDataSource,LARSessionDelegateProtocol>

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;

@end
