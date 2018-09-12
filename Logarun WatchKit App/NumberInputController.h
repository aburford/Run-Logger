//
//  NumberInputController.h
//  Logarun
//
//  Created by Andrew Burford on 6/16/16.
//  Copyright © 2016 Andrew Burford. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>
#import "InterfaceController.h"

@interface NumberInputController : WKInterfaceController

@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *numberLabel;

@end
