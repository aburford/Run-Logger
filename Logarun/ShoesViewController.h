//
//  ShoeViewController.h
//  Logarun
//
//  Created by Andrew Burford on 6/17/16.
//  Copyright © 2016 Andrew Burford. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TabBarController.h"
#import "LARSession.h"

@interface ShoesViewController : UIViewController <LARSessionDelegateProtocol, NSXMLParserDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UITextView *infoTextView;

-(void)didReceiveShoeXML:(NSData*)XMLData;

@end
