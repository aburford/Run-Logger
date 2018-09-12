//
//  CommentTableViewController.m
//  Run Logger
//
//  Created by Andrew Burford on 9/26/16.
//  Copyright © 2016 Andrew Burford. All rights reserved.
//

#import "CommentTableViewController.h"
#import "TeamMemberView.h"
#import "TabBarController.h"
#import "LARSession.h"

@interface CommentTableViewController () {
    LARRun *run;
    NSString *name;
    TeamMemberView *OP;
    int previouswidth;
    NSString *commentBody;
}

@end

@implementation CommentTableViewController

-(void)viewWillLayoutSubviews {
    if (previouswidth != self.view.window.frame.size.width) {
        previouswidth = self.view.window.frame.size.width;
        [self.tableView reloadData];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    previouswidth = self.view.window.frame.size.width;
    
    OP = [[TeamMemberView alloc] initWithFrame:CGRectMake(0, 0, self.view.window.frame.size.width, 0)];
    [OP setName:name];
    [OP setTableView:self];
    [OP setLARRun:run];
    
    [self setTitle:name];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (IBAction)newCommentPressed:(id)sender {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"New Comment"
                                                                   message:@"Type your comment below"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* postAction = [UIAlertAction actionWithTitle:@"Post" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        // create loading indicator
        UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        activityIndicator.frame = CGRectMake(0, 0, 20, 20);
        UIBarButtonItem *activity = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
        [[self navigationItem] setRightBarButtonItem:activity];
        [activityIndicator startAnimating];
        // post comment
        commentBody = alert.textFields[0].text;
        [((TabBarController*)self.tabBarController).theSession postComment:alert.textFields[0].text onRun:run delegate:self];
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {}];
    [alert addAction:cancel];
    [alert addAction:postAction];
    [self presentViewController:alert animated:YES completion:nil];

}

-(void)commentPostedWithStatus:(CommentPostStatus)status {
    switch (status) {
        case CommentPostSucceeded:{
            dispatch_async(dispatch_get_main_queue(), ^{
                TabBarController *theController = (TabBarController*)self.tabBarController;
                NSMutableArray *tempCommenters = [run.commentersArr mutableCopy];
                NSMutableArray *tempComments = [run.commentsArr mutableCopy];
                [tempCommenters addObject:[theController.theSession getUsername]];
                [tempComments addObject:commentBody];
                run.commentersArr = tempCommenters;
                run.commentsArr = tempComments;
                [[self navigationController] popViewControllerAnimated:YES];
            });
            break;
        }
        case CommentPostConnectionFailed: {
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Connection Error"
                                                                           message:@"Unable to connect to LogARun servers. Please check your network connection."
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {
                                                                      [self.navigationController popViewControllerAnimated:YES];
                                                                  }];
            [alert addAction:defaultAction];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self presentViewController:alert animated:YES completion:nil];
            });
        }
            break;
        case CommentPostPermissionDenied: {
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Permission Denied"
                                                                           message:@"This user has set their comment persmissions so that you are unable to comment on their posts. These permissions can be changed from directly within the Run Logger app."
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {
                                                                      [self.navigationController popViewControllerAnimated:YES];
                                                                  }];
            [alert addAction:defaultAction];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self presentViewController:alert animated:YES completion:nil];
            });
            break;
        }
        default:
            break;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)setLARRun:(LARRun *)newRun andName:(NSString*)newName {
    run = newRun;
    name = newName;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([run.commentsArr count] > 0) {
        return [run.commentersArr count] + 1;
    } else {
        return [run.commentsArr count] + 2;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath indexAtPosition:1] == 0) {
        return OP.view.frame.size.height;
    } else if ([indexPath indexAtPosition:1] <= [run.commentsArr count]) {
        NSString *comment = run.commentsArr[[indexPath indexAtPosition:1] - 1];
        CGRect frame = [comment boundingRectWithSize:CGSizeMake(self.view.window.frame.size.width, 1000) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:15]} context:nil];
        return frame.size.height + 25;
    } else {
        return 40;
    }
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    //UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    if ([indexPath indexAtPosition:1] == 0) {
        // original poster cell
        [OP setLARRun:run];
        [cell.contentView addSubview:OP.view];
    } else if ([indexPath indexAtPosition:1] < [run.commentsArr count] + 1) {
        // regular comment cell
        UILabel *nameLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.window.frame.size.width, 20)];
        nameLbl.text = run.commentersArr[[indexPath indexAtPosition:1] - 1];
        nameLbl.font = [UIFont systemFontOfSize:17];
        UILabel *commentLbl = [[UILabel alloc] init];
        commentLbl.text = run.commentsArr[[indexPath indexAtPosition:1] - 1];
        commentLbl.numberOfLines = 0;
        commentLbl.font = [UIFont systemFontOfSize:15];
        CGRect frame = [commentLbl.text boundingRectWithSize:CGSizeMake(self.view.window.frame.size.width, 1000) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:commentLbl.font} context:nil];
        commentLbl.frame = CGRectMake(0, 20, frame.size.width, frame.size.height + 5);
        [cell.contentView addSubview:nameLbl];
        [cell.contentView addSubview:commentLbl];
    } else {
        cell.textLabel.text = @"No comments";
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
    }
    
    if ([indexPath indexAtPosition:1] % 2 == 1) {
        cell.backgroundColor = [UIColor colorWithRed:0.99 green:1.00 blue:0.84 alpha:1.0];
    } else {
        cell.backgroundColor = [UIColor colorWithRed:0.90 green:0.93 blue:0.78 alpha:1.0];
    }
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
