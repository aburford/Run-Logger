//
//  NumberInputController.m
//  Logarun
//
//  Created by Andrew Burford on 6/16/16.
//  Copyright © 2016 Andrew Burford. All rights reserved.
//

#import "NumberInputController.h"

@interface NumberInputController ()

@end

@implementation NumberInputController {
    InterfaceController *delegate;
    NSString *numberString;
}

- (IBAction)allClearPressed {
    numberString = @"";
    [_numberLabel setText:numberString];
    [delegate newNumberReturned:numberString];
}
- (IBAction)decimalPressed {
    numberString = [numberString stringByAppendingString:@"."];
    [_numberLabel setText:numberString];
    [delegate newNumberReturned:numberString];
}
- (IBAction)backspacePressed {
    if (numberString.length > 0) {
        numberString = [numberString substringToIndex:numberString.length-1];
        [_numberLabel setText:numberString];
        [delegate newNumberReturned:numberString];
    }
}
- (IBAction)onePressed {
    numberString = [numberString stringByAppendingString:@"1"];
    [_numberLabel setText:numberString];
    [delegate newNumberReturned:numberString];
}
- (IBAction)twoPressed {
    numberString = [numberString stringByAppendingString:@"2"];
    [_numberLabel setText:numberString];
    [delegate newNumberReturned:numberString];
}
- (IBAction)threePressed {
    numberString = [numberString stringByAppendingString:@"3"];
    [_numberLabel setText:numberString];
    [delegate newNumberReturned:numberString];
}
- (IBAction)fourPressed {
    numberString = [numberString stringByAppendingString:@"4"];
    [_numberLabel setText:numberString];
    [delegate newNumberReturned:numberString];
}
- (IBAction)fivePressed {
    numberString = [numberString stringByAppendingString:@"5"];
    [_numberLabel setText:numberString];
    [delegate newNumberReturned:numberString];
}
- (IBAction)sixPressed {
    numberString = [numberString stringByAppendingString:@"6"];
    [_numberLabel setText:numberString];
    [delegate newNumberReturned:numberString];
}
- (IBAction)sevenPressed {
    numberString = [numberString stringByAppendingString:@"7"];
    [_numberLabel setText:numberString];
    [delegate newNumberReturned:numberString];
}
- (IBAction)eightPressed {
    numberString = [numberString stringByAppendingString:@"8"];
    [_numberLabel setText:numberString];
    [delegate newNumberReturned:numberString];
}
- (IBAction)ninePressed {
    numberString = [numberString stringByAppendingString:@"9"];
    [_numberLabel setText:numberString];
    [delegate newNumberReturned:numberString];
}
- (IBAction)zeroPressed {
    numberString = [numberString stringByAppendingString:@"0"];
    [_numberLabel setText:numberString];
    [delegate newNumberReturned:numberString];
}

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    // Configure interface objects here.
    delegate = context[0];
    if ([context[1] isEqualToString:@"0.00"]) {
        numberString = @"";
    } else {
        numberString = context[1];
    }
    [_numberLabel setText:numberString];
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

@end



