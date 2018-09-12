//
//  TeamCalTableViewController.h
//  Run Logger
//
//  Created by Andrew Burford on 9/22/16.
//  Copyright © 2016 Andrew Burford. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TabBarController.h"
#import "CommentTableViewController.h"

@interface TeamCalTableViewController : UITableViewController <LARSessionDelegateProtocol,UISearchBarDelegate,UISearchControllerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *forwardButton;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;


-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText;
-(int)getWidth;
-(void)setTeamID:(NSString*)newTeamID;
-(void)didReceiveTeamRunsDict:(NSMutableDictionary *)teamRunsDict withDate:(NSDate *)date;

@end
