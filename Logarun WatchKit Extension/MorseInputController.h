//
//  MorseInputController.h
//  Logarun
//
//  Created by Andrew Burford on 5/5/16.
//  Copyright © 2016 Andrew Burford. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>
#import "InterfaceController.h"

@interface MorseInputController : WKInterfaceController

@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *resultStringLbl;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceButton *dictationInputButton;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *codeInputIndicator;

@end
