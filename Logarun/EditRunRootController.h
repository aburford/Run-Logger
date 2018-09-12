//
//  EditRunRootController.h
//  Logarun
//
//  Created by Andrew Burford on 5/18/16.
//  Copyright © 2016 Andrew Burford. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EditViewController.h"
#import "EditView2Controller.h"
#import "LARRun.h"
#import "EditViewProtocol.h"
#import "MultipleRunsViewController.h"


@interface EditRunRootController : UIViewController <UIPageViewControllerDataSource,UIPageViewControllerDelegate,LARSessionDelegateProtocol>

@property (nonatomic,strong) UIPageViewController *PageViewController;

@property (nonatomic, strong) MultipleRunsViewController *page0;
@property (nonatomic,strong) EditViewController *page1;
@property (nonatomic,strong) EditView2Controller *page2;

@property (nonatomic) NSString *dateString;
@property (nonatomic) NSDate *runDate;
@property (nonatomic,strong) LARRun *theRun;
@property (weak, nonatomic) IBOutlet UINavigationItem *navigationTitle;

-(void)runPosted;

@end
