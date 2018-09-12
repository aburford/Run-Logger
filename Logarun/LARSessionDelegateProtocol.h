//
//  LARSessionDelegateProtocol.h
//  Logarun
//
//  Created by Andrew Burford on 5/4/16.
//  Copyright © 2016 Andrew Burford. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LARSession.h"
#import "LARRun.h"

typedef enum {
    CreationFailedDuplicateName,
    CreationFailedOther,
    CreationFailedNoConnection,
    CreationSucceeded
} CreationStatus;

typedef enum {
    CommentPermissionDefault,
    CommentPermissionNoOne,
    CommentPermissionCoaches,
    CommentPermissionTeamMembers,
    CommentPermissionAllUsers,
    CommentPermissionEveryone
} CommentPermission;

typedef enum {
    CommentPostConnectionFailed,
    CommentPostSucceeded,
    CommentPostPermissionDenied
} CommentPostStatus;

@protocol LARSessionDelegateProtocol <NSObject>

@optional

-(void)didReceiveCommentViewPermissions:(CommentPermission)viewPermission writePermissions:(CommentPermission)writePermission;
-(void)preferencesUpdated:(BOOL)success;
-(void)sessionDidLogin:(bool)success;
-(void)didReceiveMileage:(double)weeklyMileage userAlreadyRan:(bool)alreadyRan;
-(void)didReceiveRun:(LARRun*)theRun forDate:(NSDate*)theDate;
-(void)runPosted;
-(void)didReceiveGeneralInfo:(NSMutableDictionary*)infoDictionary;
-(void)didReceiveShoeXML:(NSData*)XMLData;
-(void)didReceiveTeamsDict:(NSMutableDictionary*)teamDict;
-(void)didReceiveTeamRunsDict:(NSMutableDictionary*)teamRunsDict withDate:(NSDate*)date;
-(void)runPostFailed;
-(void)accountCreationReceivedResponse:(CreationStatus)status;
-(void)commentPostedWithStatus:(CommentPostStatus)status;
-(void)sqlAuthIdDeleted;

@end
