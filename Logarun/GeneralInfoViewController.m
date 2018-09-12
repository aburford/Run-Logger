//
//  GeneralInfoViewController.m
//  Logarun
//
//  Created by Andrew Burford on 6/17/16.
//  Copyright © 2016 Andrew Burford. All rights reserved.
//

#import "GeneralInfoViewController.h"

@interface GeneralInfoViewController ()

@end

@implementation GeneralInfoViewController {
    NSMutableDictionary *previousInfoDict;
    int previousScreenWidth;
}

- (void)viewDidLoad {
    previousScreenWidth = self.view.frame.size.width;
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setTitle:@"General Info"];
    TabBarController *theController = (TabBarController*)self.tabBarController;
    [theController.theSession getGeneralInfoToDelegate:self];
}

-(void)didReceiveGeneralInfo:(NSMutableDictionary *)infoDictionary {
    if (infoDictionary) {
        previousInfoDict = infoDictionary;
        dispatch_async(dispatch_get_main_queue(), ^{
            [_activityIndicator stopAnimating];
            int blockHeight = 30;
            int __block y = self.navigationController.navigationBar.frame.size.height + self.navigationController.navigationBar.frame.origin.y;
            int screenWidth = self.view.frame.size.width;
            [infoDictionary enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                UILabel *keyLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, y, screenWidth/2 - 1, blockHeight)];
                keyLabel.text = [NSString stringWithFormat:@"%@",key];
                keyLabel.backgroundColor = [UIColor colorWithRed:0.90 green:0.93 blue:0.78 alpha:1.0];
                [self.view addSubview:keyLabel];
                UILabel *valueLabel = [[UILabel alloc] initWithFrame:CGRectMake(screenWidth/2 + 1, y, screenWidth/2 - 1, blockHeight)];
                valueLabel.text = [NSString stringWithFormat:@"%@",obj];
                valueLabel.backgroundColor = [UIColor colorWithRed:0.90 green:0.93 blue:0.78 alpha:1.0];
                [self.view addSubview:valueLabel];
                y += blockHeight + 2;
            }];
            UITextView *infoLbl = [[UITextView alloc] initWithFrame:CGRectMake(0, y, screenWidth, blockHeight)];
            infoLbl.scrollEnabled = false;
            infoLbl.dataDetectorTypes = UIDataDetectorTypeAll;
            infoLbl.textAlignment = NSTextAlignmentCenter;
            infoLbl.text = @"Edit this info at logarun.com";
            infoLbl.font = [UIFont systemFontOfSize:16];
            infoLbl.editable = false;
            infoLbl.selectable = true;
            infoLbl.backgroundColor = [UIColor colorWithRed:0.90 green:0.93 blue:0.78 alpha:1.0];
            [self.view addSubview:infoLbl];
        });
    } else {
        NSLog(@"general info failed to load");
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
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidLayoutSubviews {
    if (previousInfoDict && previousScreenWidth != self.view.frame.size.width) {
        [[self.view subviews] enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj removeFromSuperview];
            obj = nil;
        }];
        [self didReceiveGeneralInfo:previousInfoDict];
        previousScreenWidth = self.view.frame.size.width;
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
