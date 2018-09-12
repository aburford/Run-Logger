//
//  CreateAccountTableViewController.m
//  Run Logger
//
//  Created by Andrew Burford on 9/14/16.
//  Copyright © 2016 Andrew Burford. All rights reserved.
//

#import "CreateAccountTableViewController.h"

@interface CreateAccountTableViewController () {
    NSMutableArray *textFieldsArr;
    UISwitch *privateSwitch;
    UIPickerView *genderPicker;
    int previousWidth;
}
@property (strong, nonatomic) IBOutlet UINavigationBar *navigationBar;


@end

@implementation CreateAccountTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    previousWidth = self.view.window.frame.size.width;
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
}

-(void)viewWillLayoutSubviews {
    if (self.view.window.frame.size.width != previousWidth && privateSwitch) {
        privateSwitch.frame = CGRectMake(self.view.window.frame.size.width - 57, 6, 51, 31);
    }
}

- (IBAction)cancelPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)donePressed:(id)sender {
    // create a loading indicator and send info to logarun
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityIndicator.frame = CGRectMake(0, 0, 20, 20);
    UIBarButtonItem *activity = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
    [[self navigationItem] setRightBarButtonItem:activity];
    [activityIndicator startAnimating];
    
    [self.navigationItem setLeftBarButtonItem:nil];
    
    NSMutableArray *values = [[NSMutableArray alloc] init];
    __block BOOL blankFields = false;
    __block BOOL overFourLetters = true;
    [textFieldsArr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [values addObject:((UITextField*)obj).text];
        NSLog(@"text:%@",((UITextField*)obj).text);
        if ([((UITextField*)obj).text isEqualToString:@""]) {
            blankFields = true;
        }
        // check that everything is over 4 letters
        if (((UITextField*)obj).text.length < 4) {
            overFourLetters = false;
        }
    }];
    if (!blankFields && overFourLetters) {
        NSString *gender;
        if ([genderPicker selectedRowInComponent:0] == 0) {
            gender = @"Male";
        } else {
            gender = @"Female";
        }
        NSLog(@"table seesion:%@",self.theLARSession);
        [self.delegate.theSession createAccountWithUsername:values[0] displayName:values[1] email:values[2] password:values[3] private:privateSwitch.on gender:gender delegate:self];
    } else if (blankFields) {
        // some fields are blank
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Some fields are blank"
                                                                       message:@"Please fill in all fields"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* okay = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction * action) {
                                                                UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(donePressed:)];
                                                                UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelPressed:)];
                                                                [self.navigationItem setLeftBarButtonItem:cancel];
                                                                [[self navigationItem] setRightBarButtonItem:done];
                                                            }];
        [alert addAction:okay];
        [self presentViewController:alert animated:YES completion:nil];
    } else if (!overFourLetters) {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                       message:@"The username, display name, and password must all be four or more characters long"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* okay = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * action) {
                                                         UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(donePressed:)];
                                                         UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelPressed:)];
                                                         [self.navigationItem setLeftBarButtonItem:cancel];
                                                         [[self navigationItem] setRightBarButtonItem:done];
                                                     }];
        [alert addAction:okay];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

-(void)dismissSelf {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated:YES completion:^{
            self.delegate.usernameTextField.text = ((UITextField*)textFieldsArr[0]).text;
            self.delegate.passwordTextField.text = ((UITextField*)textFieldsArr[3]).text;
            [self.delegate loginButtonPressed:self];
        }];
    });
}

-(void)accountCreationReceivedResponse:(CreationStatus)status {
    switch (status) {
        case CreationSucceeded:
            
            [self dismissSelf];
            break;
        case CreationFailedDuplicateName: {
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                           message:@"Username already taken"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* okay = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {
                                                             UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(donePressed:)];
                                                             UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelPressed:)];
                                                             [self.navigationItem setLeftBarButtonItem:cancel];
                                                             [[self navigationItem] setRightBarButtonItem:done];
                                                         }];
            [alert addAction:okay];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self presentViewController:alert animated:YES completion:nil];
            });
        }
            break;
        case CreationFailedOther: {
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Failed To Create Account"
                                                                           message:@"Please don't use any unusual characters or spaces and make sure your email is correct."
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* okay = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {
                                                             UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(donePressed:)];
                                                             UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelPressed:)];
                                                             [self.navigationItem setLeftBarButtonItem:cancel];
                                                             [[self navigationItem] setRightBarButtonItem:done];
                                                         }];
            [alert addAction:okay];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self presentViewController:alert animated:YES completion:nil];
            });
        }
            break;
        case CreationFailedNoConnection: {
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Connection Error"
                                                                           message:@"Unable to connect to LogARun servers. Please check your network connection."
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* okay = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {
                                                             UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(donePressed:)];
                                                             UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelPressed:)];
                                                             [self.navigationItem setLeftBarButtonItem:cancel];
                                                             [[self navigationItem] setRightBarButtonItem:done];
                                                         }];
            [alert addAction:okay];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self presentViewController:alert animated:YES completion:nil];
            });
        }
            break;
        default:
            break;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Picker View Stuff

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return 2;
}

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (!genderPicker) {
        genderPicker = pickerView;
    }
    NSString *title;
    switch (row) {
        case 0:
            title = @"Male";
            break;
        case 1:
            title = @"Female";
            break;
        default:
            NSLog(@"whoops");
            break;
    }
    return title;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 6;
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    if ([indexPath indexAtPosition:1] != 5) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"generic" forIndexPath:indexPath];
    }
    if (!textFieldsArr) {
        textFieldsArr = [[NSMutableArray alloc] init];
        for (int i = 0; i < 4; i++) {
            UITextField *editingField = [[UITextField alloc] initWithFrame:CGRectMake(16, 0, cell.frame.size.width, cell.frame.size.height)];
            if (i == 0) {
                [editingField becomeFirstResponder];
            }
            [textFieldsArr addObject:editingField];
        }
    }
    switch ([indexPath indexAtPosition:1]) {
        case 0:
            ((UITextField*)textFieldsArr[[indexPath indexAtPosition:1]]).placeholder = @"Username";
            [cell.contentView addSubview:textFieldsArr[[indexPath indexAtPosition:1]]];
            break;
        case 1:
            ((UITextField*)textFieldsArr[[indexPath indexAtPosition:1]]).placeholder = @"Display Name";
            [cell.contentView addSubview:textFieldsArr[[indexPath indexAtPosition:1]]];
            break;
        case 2:
            ((UITextField*)textFieldsArr[[indexPath indexAtPosition:1]]).placeholder = @"Email";
            ((UITextField*)textFieldsArr[[indexPath indexAtPosition:1]]).keyboardType = UIKeyboardTypeEmailAddress;
            [cell.contentView addSubview:textFieldsArr[[indexPath indexAtPosition:1]]];
            break;
        case 3:
            ((UITextField*)textFieldsArr[[indexPath indexAtPosition:1]]).placeholder = @"Password";
            ((UITextField*)textFieldsArr[[indexPath indexAtPosition:1]]).secureTextEntry = YES;
            [cell.contentView addSubview:textFieldsArr[[indexPath indexAtPosition:1]]];
            break;
        case 4:
            cell.textLabel.text = @"Private";
            cell.textLabel.font = [UIFont systemFontOfSize:17.0f];
            if (!privateSwitch) {
                privateSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(cell.frame.size.width - 57, 6, 51, 31)];
                privateSwitch.on = YES;
            }
            [cell addSubview:privateSwitch];
            break;
        case 5:
            cell = [tableView dequeueReusableCellWithIdentifier:@"genderPicker"];
            break;
        default:
            NSLog(@"should not be happending");
            break;
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


#pragma mark - Navigation





@end
