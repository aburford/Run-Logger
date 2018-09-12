//
//  TeamMemberView.m
//  Logarun
//
//  Created by Andrew Burford on 6/22/16.
//  Copyright © 2016 Andrew Burford. All rights reserved.
//

#import "TeamMemberView.h"

@implementation TeamMemberView {
    UILabel *nameLbl;
    UILabel *distanceLbl;
    UILabel *durationLbl;
    UILabel *dayTitleLbl;
    UILabel *noteLbl;
    UILabel *commentsLbl;
    UILabel *paceLbl;
    int previousWidth;
    UITableViewController *theTableView;
    LARRun *run;
    NSMutableArray<UILabel*> *removableLbls;
}

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super init];
    self.view = [[UIView alloc] initWithFrame:frame];
    return self;
}

-(void)setName:(NSString *)name {
    previousWidth = self.view.frame.size.width;
    nameLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, previousWidth / 3, 20)];
    nameLbl.textAlignment = NSTextAlignmentCenter;
    nameLbl.font = [UIFont systemFontOfSize:17];
    nameLbl.text = name;
    [self.view addSubview:nameLbl];
    removableLbls = [[NSMutableArray alloc] init];
}

-(void)setTableView:(UITableViewController *)newTableView {
    theTableView = newTableView;
}

-(void)setLARRun:(LARRun *)theRun {
    run = theRun;
    previousWidth = theTableView.view.window.frame.size.width;
    nameLbl.frame = CGRectMake(0, 0, previousWidth / 3, 20);
    
    [removableLbls enumerateObjectsUsingBlock:^(UILabel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
        obj = nil;
    }];
    
    if (!distanceLbl) {
        distanceLbl = [[UILabel alloc] initWithFrame:CGRectMake(previousWidth / 3, 0, previousWidth / 3, 20)];
        distanceLbl.textAlignment = NSTextAlignmentCenter;
        distanceLbl.font = [UIFont systemFontOfSize:17];
        [self.view addSubview:distanceLbl];
    }
    distanceLbl.frame = CGRectMake(previousWidth / 3, 0, previousWidth / 3, 20);
    distanceLbl.text = theRun.totalDistance;

    if (!durationLbl) {
        durationLbl = [[UILabel alloc] initWithFrame:CGRectMake(previousWidth * 2 / 3, 0, previousWidth / 3, 20)];
        durationLbl.textAlignment = NSTextAlignmentCenter;
        durationLbl.font = [UIFont systemFontOfSize:17];
        [self.view addSubview:durationLbl];
    }
    durationLbl.frame = CGRectMake(previousWidth * 2 / 3, 0, previousWidth / 3, 20);
    durationLbl.text = theRun.totalDuration;
    
    __block int height = 20;
    for (int i = 0; i < [theRun.distances count]; i++) {
        if ([theRun.distances count] > i) {
            UILabel *distancesLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, height, previousWidth / 3, 20)];
            distancesLbl.text = theRun.distances[i];
            distancesLbl.font = [UIFont systemFontOfSize:15];
            distancesLbl.textAlignment = NSTextAlignmentCenter;
            [self.view addSubview:distancesLbl];
            [removableLbls addObject:distancesLbl];
        }
        
        if ([theRun.durations count] > i) {
            UILabel *durationsLbl = [[UILabel alloc] initWithFrame:CGRectMake(previousWidth / 3, height, previousWidth / 3, 20)];
            durationsLbl.text = theRun.durations[i];
            durationsLbl.font = [UIFont systemFontOfSize:15];
            durationsLbl.textAlignment = NSTextAlignmentCenter;
            [self.view addSubview:durationsLbl];
            [removableLbls addObject:durationsLbl];
        }
        
        if ([theRun.paces count] > i) {
            UILabel *pacesLbl = [[UILabel alloc] initWithFrame:CGRectMake(previousWidth * 2 / 3, height, previousWidth / 3, 20)];
            pacesLbl.text = theRun.paces[i];
            pacesLbl.font = [UIFont systemFontOfSize:15];
            pacesLbl.textAlignment = NSTextAlignmentCenter;
            [self.view addSubview:pacesLbl];
            [removableLbls addObject:pacesLbl];
        }
        height += 20;
    }
    if (!theRun.distances) {
        // make a pace label
        if (!paceLbl) {
            paceLbl = [[UILabel alloc] init];
            paceLbl.textAlignment = NSTextAlignmentCenter;
            paceLbl.font = [UIFont systemFontOfSize:15];
            [self.view addSubview:paceLbl];
        }
        paceLbl.frame = CGRectMake(previousWidth * 2 / 3, 20, previousWidth / 3, 20);
        paceLbl.text = theRun.paces[0];
    } else if (paceLbl) {
        [paceLbl removeFromSuperview];
        paceLbl = nil;
    }
    
    if (!dayTitleLbl) {
        dayTitleLbl = [[UILabel alloc] init];
        dayTitleLbl.font = [UIFont systemFontOfSize:15];
        [self.view addSubview:dayTitleLbl];
    }
    if (paceLbl && paceLbl.text) {
        dayTitleLbl.frame = CGRectMake(0, height, previousWidth * 2 / 3, 20);
    } else {
        dayTitleLbl.frame = CGRectMake(0, height, previousWidth, 20);
    }
    dayTitleLbl.text = [NSString stringWithFormat:@"Day Title: %@",theRun.dayTitle];
    height += 20;
    
    if (!noteLbl) {
        noteLbl = [[UILabel alloc] init];
        noteLbl.font = [UIFont systemFontOfSize:15];
        [self.view addSubview:noteLbl];
    }
    noteLbl.text = [NSString stringWithFormat:@"Daily Note: %@",theRun.note];
    noteLbl.numberOfLines = 0;
    CGRect frame = [noteLbl.text boundingRectWithSize:CGSizeMake(previousWidth, 1000) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:noteLbl.font} context:nil];
    noteLbl.frame = CGRectMake(0, height, frame.size.width, frame.size.height);
    int commentHeight = 0;
    if (run.commentersArr) {
        if (!commentsLbl) {
            commentsLbl = [[UILabel alloc] init];
            commentsLbl.font = [UIFont systemFontOfSize:15];
            commentsLbl.textColor = [UIColor redColor];
            [self.view addSubview:commentsLbl];
        }
        commentsLbl.frame = CGRectMake(0, frame.size.height + height, previousWidth, 20);
        commentsLbl.text = [NSString stringWithFormat:@"Comments: %ld",(unsigned long)[run.commentersArr count]];
        commentHeight = 20;
    } else {
        [commentsLbl removeFromSuperview];
        commentsLbl = nil;
    }
    frame.size.height += 8 + height + commentHeight;
    self.view.frame = frame;
}
/*
-(void)repositionElements {
    if (previousWidth != self.window.frame.size.width && noteLbl) {
        // orientation changed, reposition elements
        previousWidth = self.window.frame.size.width;
        nameLbl.frame = CGRectMake(0, 0, previousWidth / 3, 20);
        distanceLbl.frame = CGRectMake(previousWidth / 3, 0, previousWidth / 3, 20);
        durationLbl.frame = CGRectMake(previousWidth * 2 / 3, 0, previousWidth / 3, 20);
        dayTitleLbl.frame = CGRectMake(0, 20, previousWidth, 20);
        CGRect frame = [noteLbl.text boundingRectWithSize:CGSizeMake(previousWidth, 1000) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:noteLbl.font} context:nil];
        noteLbl.frame = CGRectMake(0, 40, frame.size.width, frame.size.height);
        // add 8 to the frame for some buffer space at the bottom
        frame.size.height += 40 + 8;
        self.frame = frame;
    }
}
*/
-(NSString *)getName {
    return nameLbl.text;
}

-(LARRun *)getRun {
    return run;
}

@end
