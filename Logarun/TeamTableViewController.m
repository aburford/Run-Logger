//
//  TeamTableViewController.m
//  Logarun
//
//  Created by Andrew Burford on 6/19/16.
//  Copyright © 2016 Andrew Burford. All rights reserved.
//

#import "TeamTableViewController.h"
#import "TeamCalTableViewController.h"

@interface TeamTableViewController ()

@end

@implementation TeamTableViewController {
    NSString *selectedTeamID;
    UIActivityIndicatorView *activityIndicator;
    bool noTeams;
    bool firstLoad;
    NSMutableDictionary *teamsDict;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    firstLoad = true;
    noTeams = false;
    
    TabBarController *theController = (TabBarController*)self.tabBarController;
    [theController.theSession getTeamsDictToDelegate:self];
    
    activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    int screenWidth = self.view.frame.size.width;
    int screenHeight = self.view.frame.size.height - self.tabBarController.view.frame.size.height / 4;
    int indicatorWidth = 50;
    int indicatorHeight = 50;
    activityIndicator.frame = CGRectMake(screenWidth / 2 - indicatorWidth / 2, screenHeight / 2 -indicatorHeight / 2, indicatorWidth, indicatorHeight);
    activityIndicator.hidesWhenStopped = YES;
    [self.view addSubview:activityIndicator];
    [activityIndicator startAnimating];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)didReceiveTeamsDict:(NSMutableDictionary *)teamDict {
    if (teamDict) {
        if (teamDict.count > 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                teamsDict = teamDict;
                [activityIndicator stopAnimating];
                [self.tableView reloadData];
            });
        } else {
            NSLog(@"setting noTeams to true");
            noTeams = true;
            teamsDict = teamDict;
            dispatch_async(dispatch_get_main_queue(), ^{
                [activityIndicator stopAnimating];
                [self.tableView reloadData];
            });
        }
    } else {
        NSLog(@"teams dict request timed out");
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Connection Error"
                                                                       message:@"Unable to connect to LogARun servers. Please check your network connection."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* retryAction = [UIAlertAction actionWithTitle:@"Retry" style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction * action) {
                                                                TabBarController *theController = (TabBarController*)self.tabBarController;
                                                                [theController.theSession getTeamsDictToDelegate:self];
                                                            }];
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction * action) {
                                                                [activityIndicator stopAnimating];
                                                            }];
        [alert addAction:defaultAction];
        [alert addAction:retryAction];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self presentViewController:alert animated:YES completion:nil];
        });
    }
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    if (teamsDict) {
        if (teamsDict.count == 0) {
            return 1;
        } else {
            return teamsDict.count;
        }
    } else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"teamCell" forIndexPath:indexPath];
    if (!noTeams) {
        cell.textLabel.text = [teamsDict allKeys][[indexPath indexAtPosition:1]];
    } else {
        cell.textLabel.text = @"Join/Create a team on the LogARun website";
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (noTeams) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"http://www.logarun.com/"]];
    } else {
        selectedTeamID = [teamsDict objectForKey:[teamsDict allKeys][[indexPath indexAtPosition:1]]];
        [self performSegueWithIdentifier:@"toTeamCalTableView" sender:self];
    }
}

-(void)viewDidAppear:(BOOL)animated {
    if (!teamsDict && !firstLoad) {
        TabBarController *theController = (TabBarController*)self.tabBarController;
        [theController.theSession getTeamsDictToDelegate:self];
        [activityIndicator startAnimating];
    }
    firstLoad = false;
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


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    //TabBarController *theController = (TabBarController*)self.tabBarController;
    //[theController.theSession getDictionaryOfTeamRunsToDelegate:[segue destinationViewController] withID:selectedTeamID];
    TeamCalTableViewController *destination = [segue destinationViewController];
    destination.teamID = selectedTeamID;
}


@end
