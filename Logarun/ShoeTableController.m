//
//  ShoeTableController.m
//  Logarun
//
//  Created by Andrew Burford on 5/25/16.
//  Copyright © 2016 Andrew Burford. All rights reserved.
//

#import "ShoeTableController.h"

@implementation ShoeTableController {
    NSDictionary *shoeDictionary;
}


-(void)viewDidLoad {
    [super viewDidLoad];
}

-(void)viewDidAppear:(BOOL)animated {
    [self.tableView selectRowAtIndexPath:[self indexForSelectedShoe:_shoeKeyProperty] animated:YES scrollPosition:UITableViewScrollPositionMiddle];
    
    self.clearsSelectionOnViewWillAppear = NO;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    _shoeKeyProperty = [shoeDictionary allKeys][[indexPath indexAtPosition:1]];
}

-(NSIndexPath*)indexForSelectedShoe:(NSString *)shoeKey {
    NSArray *keyArray = [shoeDictionary allKeys];
    NSUInteger indexArr[] = {0,[keyArray indexOfObject:shoeKey]};
    NSIndexPath *newPath = [NSIndexPath indexPathWithIndexes:indexArr length:2];
    
    return newPath;
    //[self.tableView selectRowAtIndexPath:newPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    TabBarController *theController = (TabBarController*)self.tabBarController;
    shoeDictionary = theController.theSession.shoeDictionary;
    return [shoeDictionary count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *theShoeCell = [tableView dequeueReusableCellWithIdentifier:@"Shoe Cell"];
    theShoeCell.textLabel.text = [shoeDictionary objectForKey:[shoeDictionary allKeys][[indexPath indexAtPosition:1]]];
    if (indexPath == [self indexForSelectedShoe:_shoeKeyProperty]){
        [self.tableView selectRowAtIndexPath:[self indexForSelectedShoe:_shoeKeyProperty] animated:YES scrollPosition:UITableViewScrollPositionMiddle];
    }
    return theShoeCell;
}


@end
