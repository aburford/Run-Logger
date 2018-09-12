//
//  TeamCalTableViewController.m
//  Run Logger
//
//  Created by Andrew Burford on 9/22/16.
//  Copyright © 2016 Andrew Burford. All rights reserved.
//

#import "TeamCalTableViewController.h"
#import "TeamMemberView.h"

@interface TeamCalTableViewController () {
    NSString *teamID;
    UIActivityIndicatorView *activityView;
    NSMutableDictionary *datesToArrayOfRuns;
    NSMutableArray *teamMemberViewsArr;
    NSMutableArray *searchedMemberViewsArr;
    NSDate *selectedDate;
    int previousWidth;
    UIView *coverView;
    BOOL isSearching;
    NSIndexPath *selectedPath;
    BOOL cancelPressed;
    NSDate *loadingPastDate;
    NSDate *loadingFutureDate;
}

@end

@implementation TeamCalTableViewController

-(int)getWidth {
    return previousWidth;
}

-(void)setTeamID:(NSString *)newTeamID {
    teamID = newTeamID;
}

- (IBAction)backButton:(id)sender {
    // ¿maybe i can remove the property outlet to the button and just use the sender formal parameter?
    NSCalendar *myCalendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    selectedDate = [myCalendar dateByAddingUnit:NSCalendarUnitWeekday value:-1 toDate:selectedDate options:0];
    if ([datesToArrayOfRuns objectForKey:selectedDate]) {
        [self updateMemberViewArrWithSelectedDate];
        [self updateNavigationTitleWithDate];
        [self recreateForwardAndBackButtons];
    } else {
        // went past current week, load next week
        UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        activityIndicator.frame = CGRectMake(0, 0, 40, 30);
        UIBarButtonItem *activity = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
        [activity setWidth:40];
        UIButton *forwardBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 40, 30)];
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:@"▶️" attributes:@{NSFontAttributeName:[UIFont fontWithName:@"Apple Color Emoji" size:24.0]}];
        [forwardBtn setAttributedTitle:attributedString forState:UIControlStateNormal];
        [forwardBtn addTarget:self action:@selector(forwardPressed:) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *forward = [[UIBarButtonItem alloc] initWithCustomView:forwardBtn];
        [forward setWidth:40];
        [self.navigationItem setRightBarButtonItems:@[forward,activity]];
        [activityIndicator startAnimating];
        
        if (!loadingPastDate) {
            loadingPastDate = selectedDate;
            TabBarController *theController = (TabBarController*)self.tabBarController;
            NSLog(@"getting new team page");
            [theController.theSession getDictionaryOfTeamRunsToDelegate:self withID:teamID withDate:selectedDate];
        }
        selectedDate = [myCalendar dateByAddingUnit:NSCalendarUnitWeekday value:1 toDate:selectedDate options:0];
    }
}

- (IBAction)forwardPressed:(id)sender {
    NSCalendar *myCalendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    selectedDate = [myCalendar dateByAddingUnit:NSCalendarUnitWeekday value:1 toDate:selectedDate options:0];
    if ([datesToArrayOfRuns objectForKey:selectedDate]) {
        [self updateMemberViewArrWithSelectedDate];
        [self updateNavigationTitleWithDate];
        [self recreateForwardAndBackButtons];
    } else {
        // went past current week, load next week
        UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        activityIndicator.frame = CGRectMake(0, 0, 40, 30);
        UIBarButtonItem *activity = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
        [activity setWidth:40];
        UIButton *backwardBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 40, 30)];
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:@"◀️" attributes:@{NSFontAttributeName:[UIFont fontWithName:@"Apple Color Emoji" size:24.0]}];
        [backwardBtn setAttributedTitle:attributedString forState:UIControlStateNormal];
        [backwardBtn addTarget:self action:@selector(backButton:) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *backward = [[UIBarButtonItem alloc] initWithCustomView:backwardBtn];
        [backward setWidth:40];
        [self.navigationItem setRightBarButtonItems:@[activity,backward]];
        [activityIndicator startAnimating];
        if (!loadingFutureDate) {
            loadingFutureDate = selectedDate;
            TabBarController *theController = (TabBarController*)self.tabBarController;
            [theController.theSession getDictionaryOfTeamRunsToDelegate:self withID:teamID withDate:selectedDate];
        }
        selectedDate = [myCalendar dateByAddingUnit:NSCalendarUnitWeekday value:-1 toDate:selectedDate options:0];
    }
}

-(void)recreateForwardAndBackButtons{
    UIButton *backwardBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 40, 30)];
    NSAttributedString *backStr = [[NSAttributedString alloc] initWithString:@"◀️" attributes:@{NSFontAttributeName:[UIFont fontWithName:@"Apple Color Emoji" size:24.0]}];
    [backwardBtn setAttributedTitle:backStr forState:UIControlStateNormal];
    [backwardBtn addTarget:self action:@selector(backButton:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *backward = [[UIBarButtonItem alloc] initWithCustomView:backwardBtn];
    [backward setWidth:40];
    
    UIButton *forwardBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 40, 30)];
    NSAttributedString *forwardStr = [[NSAttributedString alloc] initWithString:@"▶️" attributes:@{NSFontAttributeName:[UIFont fontWithName:@"Apple Color Emoji" size:24.0]}];
    [forwardBtn setAttributedTitle:forwardStr forState:UIControlStateNormal];
    [forwardBtn addTarget:self action:@selector(forwardPressed:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *forward = [[UIBarButtonItem alloc] initWithCustomView:forwardBtn];
    [forward setWidth:40];
    [self.navigationItem setRightBarButtonItems:@[forward,backward]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    isSearching = false;
    
    searchedMemberViewsArr = [[NSMutableArray alloc] init];
    
    NSDate *today = [NSDate date];
    NSCalendar *myCalendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [myCalendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:today];
    selectedDate = [myCalendar dateFromComponents:components];
    [self updateNavigationTitleWithDate];
    
    TabBarController *theController = (TabBarController*)self.tabBarController;
    [theController.theSession getDictionaryOfTeamRunsToDelegate:self withID:teamID withDate:selectedDate];
    
    previousWidth = self.view.window.frame.size.width;
    
    coverView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    //coverView.backgroundColor = [UIColor colorWithRed:0.99 green:1.00 blue:0.84 alpha:1.0];
    coverView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:coverView];
    
    activityView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(self.view.frame.size.width / 2 - 25, self.view.frame.size.height / 2 - 100, 50, 50)];
    activityView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    [activityView startAnimating];
    [coverView addSubview:activityView];
    
    self.clearsSelectionOnViewWillAppear = YES;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

-(void)updateNavigationTitleWithDate {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM/dd/yyyy"];
    [self.navigationItem setTitle:[dateFormatter stringFromDate:selectedDate]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    if (previousWidth != self.view.window.frame.size.width) {
        previousWidth = self.view.window.frame.size.width;
        [self updateMemberViewArrWithSelectedDate];
    }
}

-(void)viewDidAppear:(BOOL)animated {
    [self updateMemberViewArrWithSelectedDate];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

-(void)didReceiveTeamRunsDict:(NSMutableDictionary *)teamRunsDict withDate:(NSDate *)date{
    if (teamRunsDict) {
        NSLog(@"received runs for date:%@",date);
        if (date == loadingPastDate) {
            loadingPastDate = nil;
        } else if (date == loadingFutureDate) {
            loadingFutureDate = nil;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [activityView stopAnimating];
            [coverView setHidden:1];
            self.tableView.separatorColor = [UIColor colorWithRed:0.99 green:1.00 blue:0.84 alpha:1.0];
        });
        // the goal here is to create a mutable dictionary where the keys are NSDates and the objects are arrays of runs for that date
        // we also need an array of team member views that already have the team member names set and are in alphabetical order
        NSMutableArray *arrayOfRunArrays;
        if (!teamMemberViewsArr) {
            teamMemberViewsArr = [[NSMutableArray alloc] init];
            NSArray *sortedArray = [teamRunsDict.allKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
            arrayOfRunArrays = [[NSMutableArray alloc] init];
            [sortedArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                // block called for every team member in alphabetical order
                
                TeamMemberView *memberView = [[TeamMemberView alloc] initWithFrame:CGRectMake(0, 0, self.view.window.frame.size.width, 0)];
                [memberView setName:obj];
                [memberView setTableView:self];
                [teamMemberViewsArr addObject:memberView];
                [arrayOfRunArrays addObject:[teamRunsDict objectForKey:obj]];
            }];
        } else {
            NSArray *sortedArray = [teamRunsDict.allKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
            arrayOfRunArrays = [[NSMutableArray alloc] init];
            [sortedArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                // block called for every team member in alphabetical order
                [arrayOfRunArrays addObject:[teamRunsDict objectForKey:obj]];
            }];
        }
        // loop through each day of the week
        NSCalendar *myCalendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
        NSUserDefaults *defaults = [[NSUserDefaults standardUserDefaults] init];
        if ([[defaults objectForKey:@"firstDayOfWeek"] isEqualToString:@"1"]) {
            // make adjustment because first day of week is monday
            myCalendar.firstWeekday = 2;
        }
        NSDate *today = date;
        NSDateComponents *weekdayComponents = [myCalendar components:NSCalendarUnitWeekday fromDate:today];
        NSDateComponents *componentsToSubtract = [[NSDateComponents alloc] init];
        if ([[defaults objectForKey:@"firstDayOfWeek"] isEqualToString:@"1"] && [weekdayComponents weekday] == 1) {
            [componentsToSubtract setDay:-6];
        } else {
            [componentsToSubtract setDay: - ([weekdayComponents weekday] - [myCalendar firstWeekday])];
        }
        NSDate *dayOfWeek = [myCalendar dateByAddingComponents:componentsToSubtract toDate:today options:0];
        NSDateComponents *components = [myCalendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:dayOfWeek];
        dayOfWeek = [myCalendar dateFromComponents:components];
        if (!datesToArrayOfRuns) {
            datesToArrayOfRuns = [[NSMutableDictionary alloc] init];
        }
        for (int i = 0; i <= 6; i++) {
            // enumerate array of run arrays, and for each run array add the run for that date to weekday array
            // this loops through each weekday
            NSMutableArray *weekDayRuns = [[NSMutableArray alloc] init];
            [arrayOfRunArrays enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                // this block supplies an array of runs for each team member, going in alphabetical order
                [weekDayRuns addObject:[obj objectAtIndex:i]];
            }];
            // now add the array of runs for the current week day to the dictionary mapping dates to run arrays
            [datesToArrayOfRuns setObject:weekDayRuns forKey:dayOfWeek];
            // and then move on to the next day
            dayOfWeek = [myCalendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:dayOfWeek options:0];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self recreateForwardAndBackButtons];
            [self updateMemberViewArrWithSelectedDate];
        });
    } else {
        // connection failed
        if (date == loadingPastDate) {
            loadingPastDate = nil;
        } else if (date == loadingFutureDate) {
            loadingFutureDate = nil;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self recreateForwardAndBackButtons];
        });
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Connection Error"
                                                                       message:@"Unable to connect to LogARun servers. Please check your network connection."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* retryAction = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
            [self.navigationController popViewControllerAnimated:YES];
        }];
        [alert addAction:retryAction];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self presentViewController:alert animated:YES completion:nil];
        });
    }
}

#pragma mark - Table view data source

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    selectedPath = indexPath;
    [self performSegueWithIdentifier:@"toCommentView" sender:self];
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (teamMemberViewsArr) {
        return 1;
    } else {
        return 0;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (teamMemberViewsArr) {
        if (isSearching) {
            return [searchedMemberViewsArr count];
        } else {
            return [teamMemberViewsArr count];
        }
    } else {
        return 0;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    TeamMemberView *teamMember;
    if (isSearching) {
        teamMember = [searchedMemberViewsArr objectAtIndex:[indexPath indexAtPosition:1]];
    } else {
        teamMember = [teamMemberViewsArr objectAtIndex:[indexPath indexAtPosition:1]];
    }
    return teamMember.view.frame.size.height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TeamMemberView *teamMember;
    if (isSearching) {
        teamMember = [searchedMemberViewsArr objectAtIndex:[indexPath indexAtPosition:1]];
    } else {
        teamMember = [teamMemberViewsArr objectAtIndex:[indexPath indexAtPosition:1]];
    }
    UITableViewCell *cell = [[UITableViewCell alloc] initWithFrame:CGRectMake(0, 0, self.view.window.frame.size.width, teamMember.view.frame.size.height)];
    [cell.contentView addSubview:teamMember.view];
    if ([indexPath indexAtPosition:1] % 2 == 1) {
        cell.backgroundColor = [UIColor colorWithRed:0.99 green:1.00 blue:0.84 alpha:1.0];
    } else {
        cell.backgroundColor = [UIColor colorWithRed:0.90 green:0.93 blue:0.78 alpha:1.0];
    }
    
    // warning: hacky code below
    UITableViewCellSelectionStyle selectionStyle = cell.selectionStyle;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    [cell setSelected:YES];
    [cell setSelected:NO];
    cell.selectionStyle = selectionStyle;
    // hackish code over
    
    return cell;
}

-(void)updateMemberViewArrWithSelectedDate {
    NSArray *runsForSelectedDate = [datesToArrayOfRuns objectForKey:selectedDate];
    [teamMemberViewsArr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        TeamMemberView *member = obj;
        [member setLARRun:runsForSelectedDate[idx]];
    }];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
        [self.tableView reloadInputViews];
    });
}

#pragma mark - Search Bar

-(void)updateSearchedArrayWithSearch:(NSString*)searchStr {
    [searchedMemberViewsArr removeAllObjects];
    [teamMemberViewsArr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        TeamMemberView *member = obj;
        if ([[member getName] rangeOfString:searchStr options:NSCaseInsensitiveSearch].location != NSNotFound) {
            [searchedMemberViewsArr addObject:member];
        }
    }];

}

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if ([searchText isEqualToString:@""]) {
        isSearching = false;
        cancelPressed = true;
        [self.tableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.05];
    } else {
        isSearching = true;
        cancelPressed = false;
        [self updateSearchedArrayWithSearch:searchText];
        [self.tableView performSelector:@selector(reloadInputViews) withObject:nil afterDelay:0];
    }
}

-(void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    [self.tableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.05];
}

-(void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    cancelPressed = true;
    [self.tableView reloadData];
    
}

-(BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar {
    if (cancelPressed) {
        return YES;
    } else {
        return NO;
    }
}

-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    isSearching = false;
    cancelPressed = true;
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
    CommentTableViewController *destination = [segue destinationViewController];
    TeamMemberView *teamMember;
    if (isSearching) {
        teamMember = [searchedMemberViewsArr objectAtIndex:[selectedPath indexAtPosition:1]];
    } else {
        teamMember = [teamMemberViewsArr objectAtIndex:[selectedPath indexAtPosition:1]];
    }
    [destination setLARRun:[teamMember getRun] andName:[teamMember getName]];
    cancelPressed = true;
    [self.searchDisplayController setActive:NO];
    isSearching = false;
}

@end
