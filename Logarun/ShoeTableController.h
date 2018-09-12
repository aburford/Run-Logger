//
//  ShoeTableController.h
//  Logarun
//
//  Created by Andrew Burford on 5/25/16.
//  Copyright © 2016 Andrew Burford. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "TabBarController.h"

@interface ShoeTableController : UITableViewController <UITableViewDelegate,UITableViewDataSource>

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;

@property (nonatomic) NSString *shoeKeyProperty;

@end
