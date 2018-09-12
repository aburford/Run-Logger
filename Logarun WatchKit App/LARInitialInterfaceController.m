//
//  LARInitialInterfaceController.m
//  Logarun
//
//  Created by Andrew Burford on 5/29/16.
//  Copyright © 2016 Andrew Burford. All rights reserved.
//

#import "LARInitialInterfaceController.h"

@interface LARInitialInterfaceController ()

@end

@implementation LARInitialInterfaceController {
    BOOL visible;
    InterfaceController *theMainView;
}

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    visible=true;
    // init WCSession in case of new context
    if([WCSession isSupported]){
        self.watchSession = [WCSession defaultSession];
        self.watchSession.delegate = self;
        [self.watchSession activateSession];
    }
    
    //check if keychain exists by creating search dictionary
    NSMutableDictionary *passwordQueryDictionary = [[NSMutableDictionary alloc] init];
    [passwordQueryDictionary setObject:(__bridge id)kSecClassInternetPassword forKey:(__bridge id)kSecClass];
    [passwordQueryDictionary setObject:@"sqlAuthCookie" forKey:(__bridge id)kSecAttrLabel];
    [passwordQueryDictionary setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
    [passwordQueryDictionary setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
    
    // Then call Keychain Services to get the password:
    CFDataRef passwordData = NULL;
    OSStatus keychainError = noErr;
    keychainError = SecItemCopyMatching((__bridge CFDictionaryRef)passwordQueryDictionary,
                                        (CFTypeRef *)&passwordData);
    if (keychainError == noErr)
    {
        // Convert the password to an NSString:
        NSString *sqlAuthCookie = [[NSString alloc] initWithBytes:[(__bridge_transfer NSData *)passwordData bytes]
                                                           length:[(__bridge NSData *)passwordData length] encoding:NSUTF8StringEncoding];
        
        NSMutableDictionary *passwordQueryDictionary = [[NSMutableDictionary alloc] init];
        [passwordQueryDictionary setObject:(__bridge id)kSecClassInternetPassword forKey:(__bridge id)kSecClass];
        [passwordQueryDictionary setObject:@"sqlAuthCookie" forKey:(__bridge id)kSecAttrLabel];
        [passwordQueryDictionary setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnAttributes];
        [passwordQueryDictionary setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
        
        // Then call Keychain Services to get the username:
        CFDictionaryRef keychainAttrDictionary = NULL;
        OSStatus keychainError = noErr;
        keychainError = SecItemCopyMatching((__bridge CFDictionaryRef)passwordQueryDictionary,
                                            (CFTypeRef *)&keychainAttrDictionary);
        if (keychainError == noErr)
        {
            NSLog(@"keychain found");
            NSLog(@"username: %@",CFDictionaryGetValue(keychainAttrDictionary, @"acct"));
            NSLog(@"sqlAuthCookie: %@",sqlAuthCookie);
            
            //login with LARSession and segue to main view
            LARWatchSession *watchLARSession = [[LARWatchSession alloc] init];
            [watchLARSession loginWithUsername:CFDictionaryGetValue(keychainAttrDictionary, @"acct") sqlAuth:sqlAuthCookie];
            NSArray *contextArray = [NSArray arrayWithObjects:watchLARSession,self, nil];
            
            
            
            
            // MAKE EVERYTHING VISIBLE
            
            
            
            
            [self presentControllerWithName:@"mainView" context:contextArray];
            visible=false;
            
        }
        
    }
    // if keychain not found then change label to say @"Please Login On Your Phone"
    else if (keychainError == errSecItemNotFound) {
        NSLog(@"no keychain found");
        
        
        
        // KEEP EVERYTHING HIDDEN, USER HAS NOT LOGGED IN
     
        
        
    }
}

/** Called on the delegate of the receiver. Will be called on startup if an applicationContext is available. */
- (void) session:(WCSession *)session didReceiveApplicationContext:(NSDictionary<NSString *,id> *)applicationContext {
    NSLog(@"WCSession received new application context");
    
    // delete previous keychains
    OSStatus keychainError = noErr;
    do {
        NSMutableDictionary *passwordQueryDictionary = [[NSMutableDictionary alloc] init];
        [passwordQueryDictionary setObject:(__bridge id)kSecClassInternetPassword forKey:(__bridge id)kSecClass];
        [passwordQueryDictionary setObject:@"sqlAuthCookie" forKey:(__bridge id)kSecAttrLabel];
        //[passwordQueryDictionary setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
        //[passwordQueryDictionary setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
            
        NSLog(@"%lu",SecItemDelete((__bridge CFDictionaryRef)passwordQueryDictionary));
        
        CFDictionaryRef tempDictionary = NULL;
        keychainError = SecItemCopyMatching((__bridge CFDictionaryRef)passwordQueryDictionary,
                                            (CFTypeRef *)&tempDictionary);
        
    } while (keychainError == noErr);
    //check if context says to logout, or if it has a new keychain to log in with
    if ([[applicationContext objectForKey:@"logout"]  isEqual: @YES]) {
        NSLog(@"context says just to logout");
        // just logout
        if (!visible) {
            [theMainView dismissController];
            
            
            
            // MAKE EVERYTHING HIDDEN
            
            
        }
    }
    else {
        NSLog(@"context has new account");
        NSMutableDictionary *newAccountDictionary = [NSMutableDictionary dictionaryWithDictionary:applicationContext];
        [newAccountDictionary removeObjectForKey:@"logout"];
        
        // add the new keychain
        SecItemAdd((__bridge CFDictionaryRef)newAccountDictionary, NULL);
        
        //login with LARSession and segue to main view
        LARWatchSession *watchLARSession = [[LARWatchSession alloc] init];
        NSString *sqlAuthCookieString = [[NSString alloc] initWithData:[newAccountDictionary objectForKey:(__bridge id)kSecValueData] encoding:NSUTF8StringEncoding];
        [watchLARSession loginWithUsername:[newAccountDictionary objectForKey:(__bridge id)kSecAttrAccount] sqlAuth:sqlAuthCookieString];
        NSArray *contextArray = [NSArray arrayWithObjects:watchLARSession,self, nil];
        
        
        
        // MAKE EVERYTHING APPEAR
        
        
        
        
        [self presentControllerWithName:@"mainView" context:contextArray];
        visible=true;
    }
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
}

-(void)mainViewInstance:(InterfaceController*)theInterfaceController {
    theMainView = theInterfaceController;
    NSLog(@"%@",theMainView);
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

@end



