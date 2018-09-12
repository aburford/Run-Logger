//
//  MorseInputController.m
//  Logarun
//
//  Created by Andrew Burford on 5/5/16.
//  Copyright © 2016 Andrew Burford. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MorseInputController.h"

@interface MorseInputController()

@end

@implementation MorseInputController {
    NSMutableDictionary *result;
    InterfaceController* delegate;
    NSString *resultString;
    NSString *morseCodeLetter;
}
- (IBAction)dotPressed {
    morseCodeLetter = [NSString stringWithFormat:@"%@·",morseCodeLetter];
    [_codeInputIndicator setText:morseCodeLetter];
}
- (IBAction)dashPressed {
    morseCodeLetter = [NSString stringWithFormat:@"%@−",morseCodeLetter];
    [_codeInputIndicator setText:morseCodeLetter];
}
- (IBAction)spacePressed {
    resultString = [NSString stringWithFormat:@"%@%@",resultString, [self translationForCode:morseCodeLetter]];
    [result setValue:resultString forKey:@"result"];
    [_resultStringLbl setText:[NSString stringWithFormat:@"%@|",[result objectForKey:@"result"]]];
    [delegate newResultReturned:result];
    morseCodeLetter = @"";
    [_codeInputIndicator setText:morseCodeLetter];
}

- (IBAction)clearDayTitleMenuItemSelected {
    morseCodeLetter = @"";
    resultString = @"";
    [result setValue:resultString forKey:@"result"];
    [_resultStringLbl setText:[NSString stringWithFormat:@"%@|",[result objectForKey:@"result"]]];
    [delegate newResultReturned:result];
    [_codeInputIndicator setText:morseCodeLetter];
}

- (IBAction)backspaceMenuItemSelected {
    if (![morseCodeLetter isEqualToString:@""]) {
        morseCodeLetter = @"";
    } else if (![resultString isEqualToString:@""]) {
        resultString = [resultString substringToIndex:resultString.length-1];
        [result setValue:resultString forKey:@"result"];
        [_resultStringLbl setText:[NSString stringWithFormat:@"%@|",[result objectForKey:@"result"]]];
        [delegate newResultReturned:result];
    }
    [_codeInputIndicator setText:morseCodeLetter];
}



- (IBAction)dictationInputButtonPressed {
    NSUserDefaults *defaults = [[NSUserDefaults standardUserDefaults] init];
    NSArray* initialPhrases;
    if ([[result valueForKey:@"resultType"] isEqualToString:@"Day Title"]) {
        if ([defaults objectForKey:@"titles"]) {
            initialPhrases = [defaults objectForKey:@"titles"];
        } else {
            initialPhrases = @[@"Blue Trails",@"Workout", @"Run at home",@"Meet Prep", @"Meet Day"];
        }
    } else {
        if ([defaults objectForKey:@"notes"]) {
            initialPhrases = [defaults objectForKey:@"notes"];
        } else {
            initialPhrases = @[@"Easy run today", @"I felt okay today",@"I felt a little tired today", @"Excited for the race tomorrow", @"I had a good race"];
        }
    }
    [self presentTextInputControllerWithSuggestions:initialPhrases allowedInputMode:WKTextInputModePlain completion:^(NSArray *results) {
        if (results && results.count > 0) {
            resultString = [results objectAtIndex:0];
            [result setValue:resultString forKey:@"result"];
            [_resultStringLbl setText:[NSString stringWithFormat:@"%@|",[result objectForKey:@"result"]]];
            [delegate newResultReturned:result];
            // Use the string or image.
        } else {
            // Nothing was selected.
        }
    }];

}

- (void)awakeWithContext:(id)context {
    result = [NSMutableDictionary dictionaryWithObjectsAndKeys:context[1],@"resultType", nil];
    delegate = context[0];
    morseCodeLetter = @"";
    resultString = context[2];
    [_resultStringLbl setText:[NSString stringWithFormat:@"%@|",resultString]];
    [self setTitle:context[1]];
}

-(NSString*)translationForCode:(NSString*)code{
    NSDictionary* morseCode = @{
                                @"·−"    : @"a",
                                @"−···"  : @"b",
                                @"−·−·"  : @"c",
                                @"−··"   : @"d",
                                @"·"     : @"e",
                                @"··−·"  : @"f",
                                @"−−·"   : @"g",
                                @"····"  : @"h",
                                @"··"    : @"i",
                                @"·−−−"  : @"j",
                                @"−·−"   : @"k",
                                @"·−··"  : @"l",
                                @"−−"    : @"m",
                                @"−·"    : @"n",
                                @"−−−"   : @"o",
                                @"·−−·"  : @"p",
                                @"−−·−"  : @"q",
                                @"·−·"   : @"r",
                                @"···"   : @"s",
                                @"−"     : @"t",
                                @"··−"   : @"u",
                                @"···−"  : @"v",
                                @"·−−"   : @"w",
                                @"−··−"  : @"x",
                                @"−·−−"  : @"y",
                                @"−−··"  : @"z",
                                @"−−−−−" : @"0",
                                @"·−−−−" : @"1",
                                @"··−−−" : @"2",
                                @"···−−" : @"3",
                                @"····−" : @"4",
                                @"·····" : @"5",
                                @"−····" : @"6",
                                @"−−···" : @"7",
                                @"−−−··" : @"8",
                                @"−−−−·" : @"9",
                                };
    if (![code  isEqual: @""]) {
        if ([morseCode objectForKey:code] != nil) {
            return [morseCode valueForKey:code];
        } else {
            return @"";
        }
    } else {
        return @" ";
    }
}

@end
