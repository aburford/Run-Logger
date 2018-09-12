//
//  SettingsTableViewController.m
//  Logarun
//
//  Created by Andrew Burford on 7/6/16.
//  Copyright © 2016 Andrew Burford. All rights reserved.
//

#import "SettingsTableViewController.h"

@interface SettingsTableViewController ()

@end

@implementation SettingsTableViewController {
    UITextField *goalField;
    NSArray *switchesArr;
    TabBarController *theController;
    NSUserDefaults *defaults;
    double screenWidth;
}

-(void)phoneSwitched {
    UISwitch *phoneSwitch = switchesArr[0];
    NSLog(@"phone: %d",phoneSwitch.on);
    [defaults setBool:phoneSwitch.on forKey:@"phone-health"];
}

-(void)watchSwitched {
    UISwitch *watchSwitch = switchesArr[1];
    [defaults setBool:watchSwitch.on forKey:@"watch-health"];
    [theController.theSession updateWatchApp];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // add banner ad?
    
    screenWidth = self.tableView.frame.size.width;
    
    theController = (TabBarController*)self.tabBarController;
    
    defaults = [[NSUserDefaults standardUserDefaults] init];
    
    goalField = [[UITextField alloc] initWithFrame:CGRectMake(screenWidth - 105, 6, 97, 30)];
    goalField.text = [NSString stringWithFormat:@"%.2lf",[defaults doubleForKey:@"mileage-goal"]];
    
    UISwitch *phoneSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(screenWidth - 57, 6, 51, 31)];
    [phoneSwitch addTarget:self action:@selector(phoneSwitched) forControlEvents:UIControlEventValueChanged];
    phoneSwitch.on = [defaults boolForKey:@"phone-health"];
    
    UISwitch *watchSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(screenWidth - 57, 6, 51, 31)];
    [watchSwitch addTarget:self action:@selector(watchSwitched) forControlEvents:UIControlEventValueChanged];
    watchSwitch.on = [defaults boolForKey:@"watch-health"];
    
    switchesArr = [NSArray arrayWithObjects:phoneSwitch, watchSwitch, nil];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath indexAtPosition:0] == 1 && [indexPath indexAtPosition:1] == 0) {
        [self performSegueWithIdentifier:@"toPresetTable" sender:self];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 2;
            break;
        case 1:
            return 2;
            break;
        default:
            return 0;
            break;
    }
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title;
    switch (section) {
        case 0:
            title = @"Phone";
            break;
        case 1:
            title = @"Apple Watch";
            break;
        default:
            break;
    }
    return title;
}

-(NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSString *title;
    switch (section) {
        case 0:
            title = @"When this is turned on, the most recent measurements for your weight and body fat percentage saved in the Health app will be automatically submitted to your LogARun post";
            break;
        case 1:
            title = @"Your Apple Watch can automatically post your weight and body fat percentage as well (just like the phone app)";
            break;
        default:
            break;
    }
    return title;
}

-(void)textFieldDidEndEditing:(UITextField *)textField {
    NSLog(@"weekly mileage changed to: %@",goalField.text);
    double goalDouble = [goalField.text doubleValue];
    [defaults setDouble:goalDouble forKey:@"mileage-goal"];
    [theController.theSession updateWatchApp];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell;
    int section = (int)[indexPath indexAtPosition:0];
    int row = (int)[indexPath indexAtPosition:1];
    switch (section) {
        case 0:
            // phone settings
            switch (row) {
                case 0:
                    cell = [tableView dequeueReusableCellWithIdentifier:@"mileageGoalCell" forIndexPath:indexPath];
                {
                    goalField.borderStyle = UITextBorderStyleNone;
                    goalField.clearButtonMode = UITextFieldViewModeWhileEditing;
                    goalField.delegate = self;
                    goalField.keyboardType = UIKeyboardTypeDecimalPad;
                    goalField.textAlignment = NSTextAlignmentCenter;
                    [cell.contentView addSubview:goalField];
                }
                    break;
                case 1:
                    cell = [tableView dequeueReusableCellWithIdentifier:@"healthDataCell" forIndexPath:indexPath];
                    [cell.contentView addSubview:switchesArr[0]];
                    
                    break;
                default:
                    break;
            }
            break;
        case 1:
            // watch settings
            switch (row) {
                case 0:
                    cell = [tableView dequeueReusableCellWithIdentifier:@"presetCell" forIndexPath:indexPath];
                    break;
                case 1:
                    cell = [tableView dequeueReusableCellWithIdentifier:@"healthDataCell" forIndexPath:indexPath];
                    [cell.contentView addSubview:switchesArr[1]];
                    
                    break;
                default:
                    break;
            }

            break;
        default:
            break;
    }
    
    return cell;
}

-(void)viewDidLayoutSubviews {
    
    if (self.tableView.frame.size.width != screenWidth) {
        screenWidth = self.tableView.frame.size.width;
        [switchesArr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            ((UISwitch*)obj).frame = CGRectMake(screenWidth - 57, 6, 51, 31);
        }];
        goalField.frame = CGRectMake(screenWidth - 105, 6, 97, 30);
    }
     
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
