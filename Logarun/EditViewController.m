//
//  EditViewController.m
//  Logarun
//
//  Created by Andrew Burford on 5/11/16.
//  Copyright © 2016 Andrew Burford. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EditViewController.h"

@interface EditViewController ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *noteContainerHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *noteHeight;


@end

@implementation EditViewController {
    NSString *dateString;
    LARRun *theRun;
}


-(void)viewDidLoad {
    [super viewDidLoad];
    [_dayTitleField becomeFirstResponder];
    _dayTitleField.text = theRun.dayTitle;
    _dailyNoteView.text = theRun.note;
    if (self.view.frame.size.height == 480) {
        // resize things for 4s
        self.noteContainerHeight.constant = 90;
        self.noteHeight.constant = 59;
    }
}

- (NSString *)stringFromTimeInterval:(NSTimeInterval)interval {
    NSInteger ti = (NSInteger)interval;
    NSInteger seconds = ti % 60;
    NSInteger minutes = (ti / 60) % 60;
    NSInteger hours = (ti / 3600);
    return [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)hours, (long)minutes, (long)seconds];
}

-(void)viewWillAppear:(BOOL)animated {
    [_dayTitleField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0];
}

-(void)setRun:(LARRun *)incomingRun {
    theRun = incomingRun;
}

@end
