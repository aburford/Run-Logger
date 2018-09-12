//
//  ShoeViewController.m
//  Logarun
//
//  Created by Andrew Burford on 6/17/16.
//  Copyright © 2016 Andrew Burford. All rights reserved.
//

#import "ShoesViewController.h"

@interface ShoesViewController ()

@end

@implementation ShoesViewController {
    int screenWidth;
    int y;
    int blockHeight;
    NSMutableArray *shoeLabels;
    UITextView *shoeInfo;
    int previousWidth;
}

- (void)viewDidLoad {
    previousWidth = self.view.frame.size.width;
    [super viewDidLoad];
    [self.navigationItem setTitle:@"Shoes"];
    // Do any additional setup after loading the view.
    TabBarController *theController = (TabBarController*)self.tabBarController;
    [theController.theSession getShoeXMLStringToDelegate:self];
    self.navigationItem.backBarButtonItem.title = @"Profile";
    //self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, self.navigationController.navigationBar.frame.size.height + self.navigationController.navigationBar.frame.origin.y, self.view.frame.size.width, 400)];
}

-(void)didReceiveShoeXML:(NSData *)XMLData {
    if (XMLData.length != 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // create a label at the top
            blockHeight = 30;
            screenWidth = self.view.frame.size.width;
            y = 0;
            
            shoeLabels = [[NSMutableArray alloc] init];
            
            // parse out the shoe xml
            [_activityIndicator stopAnimating];
            NSXMLParser *newParser = [[NSXMLParser alloc] initWithData:XMLData];
            newParser.delegate = self;
            newParser.shouldProcessNamespaces = NO;
            [newParser parse];
        });
    } else {
        [_activityIndicator stopAnimating];
        NSLog(@"request for shoe xml failed");
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Connection Error"
                                                                       message:@"Unable to connect to LogARun servers. Please check your network connection."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  [self.navigationController popViewControllerAnimated:YES];
                                                              }];
        [alert addAction:defaultAction];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self presentViewController:alert animated:YES completion:^{}];
        });

    }
}

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary<NSString *,NSString *> *)attributeDict {
    // create a new row for each new shoe
    if ([elementName isEqualToString:@"shoe"]) {
        
        UILabel *nameHeaderLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, y, screenWidth, blockHeight)];
        nameHeaderLabel.text = [NSString stringWithFormat:@"%@",[attributeDict objectForKey:@"name"]];
        nameHeaderLabel.textAlignment = NSTextAlignmentCenter;
        nameHeaderLabel.backgroundColor = [UIColor colorWithRed:0.90 green:0.93 blue:0.78 alpha:1.0];
        
        y += blockHeight;
        
        UILabel *milesHeaderLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, y, screenWidth / 2, blockHeight)];
        NSString *mileage = [attributeDict objectForKey:@"currDistance"];
        if (mileage.length > 2) {
            mileage = [mileage substringToIndex:mileage.length - 2];
        }
        milesHeaderLabel.text = [NSString stringWithFormat:@"Miles Ran: %@",mileage];
        milesHeaderLabel.textAlignment = NSTextAlignmentCenter;
        milesHeaderLabel.backgroundColor = [UIColor colorWithRed:0.90 green:0.93 blue:0.78 alpha:1.0];
        
        UILabel *maxHeaderLabel = [[UILabel alloc] initWithFrame:CGRectMake(screenWidth / 2, y, screenWidth / 2, blockHeight)];
        mileage = [attributeDict objectForKey:@"maxDistance"];
        
        maxHeaderLabel.text = [NSString stringWithFormat:@"Max Mileage: %@",mileage];
        maxHeaderLabel.textAlignment = NSTextAlignmentCenter;
        maxHeaderLabel.backgroundColor = [UIColor colorWithRed:0.90 green:0.93 blue:0.78 alpha:1.0];
        
        [shoeLabels addObject:nameHeaderLabel];
        [shoeLabels addObject:milesHeaderLabel];
        [shoeLabels addObject:maxHeaderLabel];
        
        [self.scrollView addSubview:nameHeaderLabel];
        [self.scrollView addSubview:milesHeaderLabel];
        [self.scrollView addSubview:maxHeaderLabel];
        y += blockHeight + 2;
    }
}

-(void)parserDidEndDocument:(NSXMLParser *)parser {
    if (y == 0) {
        // use has no shoes
        [_infoTextView setHidden:NO];
    } else {
        shoeInfo = [[UITextView alloc] initWithFrame:CGRectMake(0, y, screenWidth, 70)];
        shoeInfo.editable = false;
        shoeInfo.selectable = true;
        shoeInfo.scrollEnabled = false;
        shoeInfo.dataDetectorTypes = UIDataDetectorTypeAll;
        shoeInfo.font = [UIFont systemFontOfSize:20];
        shoeInfo.textAlignment = NSTextAlignmentCenter;
        shoeInfo.backgroundColor = [UIColor clearColor];
        shoeInfo.text = @"Add and edit shoes on the logarun.com website";
        [self.scrollView addSubview:shoeInfo];
        y += shoeInfo.frame.size.height;
        self.scrollView.contentSize = CGSizeMake(screenWidth, y);
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidLayoutSubviews {
    if (previousWidth != self.view.frame.size.width && shoeLabels) {
        y = 0;
        screenWidth = self.view.frame.size.width;
        [shoeLabels enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            switch (idx % 3) {
                case 0:
                    // name label
                    ((UILabel*)obj).frame = CGRectMake(0, y, screenWidth, blockHeight);
                    y += blockHeight;
                    break;
                case 1:
                    ((UILabel*)obj).frame = CGRectMake(0, y, screenWidth / 2, blockHeight);
                    // miles label
                    break;
                case 2:
                    // max label
                    ((UILabel*)obj).frame = CGRectMake(screenWidth / 2, y, screenWidth / 2, blockHeight);
                    y += blockHeight + 2;
                    break;
                default:
                    break;
            }
        }];
        // and edit shoe info label
        shoeInfo.frame = CGRectMake(0, y, screenWidth, 70);
        y += shoeInfo.frame.size.height;
        
        // then update the scrollview
        self.scrollView.contentSize = CGSizeMake(screenWidth, y);
        previousWidth = self.view.frame.size.width;
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
