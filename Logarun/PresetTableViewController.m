//
//  PresetTableViewController.m
//  Logarun
//
//  Created by Andrew Burford on 7/6/16.
//  Copyright © 2016 Andrew Burford. All rights reserved.
//

#import "PresetTableViewController.h"

@interface PresetTableViewController ()

@end

@implementation PresetTableViewController {
    NSMutableDictionary *titleDict;
    NSMutableDictionary *noteDict;
    
    NSUserDefaults *defaults;
    NSMutableArray *titleArr;
    NSMutableArray *noteArr;
    
    TabBarController *theController;
    double screenWidth;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    theController = (TabBarController*)self.tabBarController;
    
    titleDict = [[NSMutableDictionary alloc] init];
    noteDict = [[NSMutableDictionary alloc] init];
    
    defaults = [[NSUserDefaults standardUserDefaults] init];
    
    titleArr = [NSMutableArray arrayWithArray:[defaults objectForKey:@"titles"]];
    noteArr = [NSMutableArray arrayWithArray:[defaults objectForKey:@"notes"]];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

-(void)viewDidDisappear:(BOOL)animated {
    [titleArr removeAllObjects];
    [titleDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if (![((UITextField*)obj).text isEqualToString:@""]) {
            [titleArr addObject:((UITextField*)obj).text];
        }
    }];
    [noteArr removeAllObjects];
    [noteDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if (![((UITextField*)obj).text isEqualToString:@""]) {
            [noteArr addObject:((UITextField*)obj).text];
        }
    }];
    // we now need to save these arrays to NSUserDefaults AND ALSO send them to the apple watch to be saved to the watch's NSUserDefaults
    [defaults setObject:titleArr forKey:@"titles"];
    [defaults setObject:noteArr forKey:@"notes"];
    
    [theController.theSession updateWatchApp];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"prototypeCell" forIndexPath:indexPath];
    
    // Configure the cell...
    if ([titleDict objectForKey:indexPath]) {
        [cell.contentView addSubview:[titleDict objectForKey:indexPath]];
    } else if ([noteDict objectForKey:indexPath]) {
        [cell.contentView addSubview:[noteDict objectForKey:indexPath]];
    } else {
        screenWidth = self.tableView.frame.size.width;
        
        UITextField *stringField = [[UITextField alloc] initWithFrame:CGRectMake(6, 0, screenWidth - 6, 43)];
        stringField.text = @"";
        
        int section = (int)[indexPath indexAtPosition:0];
        NSUInteger row = [indexPath indexAtPosition:1];
        switch (section) {
            case 0:
                if (row >= titleArr.count) {
                    stringField.text = @"";
                } else {
                    stringField.text = [titleArr objectAtIndex:row];
                }
                break;
            case 1:
                if (row >= noteArr.count) {
                    stringField.text = @"";
                } else {
                    stringField.text = [noteArr objectAtIndex:row];
                }
                break;
            default:
                break;
        }
        
        stringField.borderStyle = UITextBorderStyleNone;
        stringField.clearButtonMode = UITextFieldViewModeWhileEditing;
        [cell.contentView addSubview:stringField];
        if ([indexPath indexAtPosition:0] == 0) {
            [titleDict setObject:stringField forKey:indexPath];
        } else {
            [noteDict setObject:stringField forKey:indexPath];
        }
    }
    
    return cell;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title;
    switch (section) {
        case 0:
            title = @"Day Title";
            break;
        case 1:
            title = @"Daily Note";
            break;
        default:
            break;
    }
    return title;
}

-(void)viewDidLayoutSubviews {
    if (self.tableView.frame.size.width != screenWidth) {
        screenWidth = self.tableView.frame.size.width;
        [[[noteDict objectEnumerator] allObjects] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            ((UITextField*)obj).frame = CGRectMake(6, 0, screenWidth - 6, 43);
        }];
        [[[titleDict objectEnumerator] allObjects] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            ((UITextField*)obj).frame = CGRectMake(6, 0, screenWidth - 6, 43);
        }];
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
