//
//  GCHelper.h
//  Skittykitts
//
//  Created by Ryan Maloney on 8/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>

@protocol GCHelperDelegate

- (void)enterNewGame:(GKTurnBasedMatch*)match;
- (void)layoutMatch:(GKTurnBasedMatch*)match;
- (void)takeTurn:(GKTurnBasedMatch*)match;
- (void)recieveEndGame:(GKTurnBasedMatch*)match;
- (void)sendNotice:(NSString*)notice
          forMatch:(GKTurnBasedMatch*)match;

@end

@interface GCHelper : NSObject <GKTurnBasedMatchmakerViewControllerDelegate, GKTurnBasedEventHandlerDelegate, UIAlertViewDelegate>
{
    BOOL gameCenterAvailable;
    BOOL userAuthenticated;
    BOOL displayedGCLoginError;
    BOOL stopGCDialogues;
    
    BOOL matchPushed;
    
    UIViewController *presentingViewController;
    
    GKTurnBasedMatch *currentMatch;
    
    id <GCHelperDelegate> delegate;
}

@property (nonatomic, retain) id <GCHelperDelegate> delegate;
@property (assign, readonly) BOOL gameCenterAvailable;
@property (assign, readwrite) BOOL matchPushed;
@property (nonatomic, retain) GKTurnBasedMatch *currentMatch;

+ (GCHelper *)sharedInstance;
- (void)authenticateLocalUser;
- (void)authenticationChanged;

- (void)findMatchWithMinPlayers:(uint)minPlayers 
                     maxPlayers:(uint)maxPlayers 
                 viewController:(UIViewController*)viewController;

@end
