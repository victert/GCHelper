//
//  GCHelper.m
//  Skittykitts
//
//  Created by Ryan Maloney on 8/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

// iOS Version Checking
#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

//#import <Availability.h>
#import "GCHelper.h"
#include "AppDelegate.h"

@implementation GCHelper

@synthesize gameCenterAvailable;
@synthesize matchPushed;
@synthesize currentMatch;
@synthesize delegate;

#pragma mark - Initialization

static GCHelper *sharedHelper = nil;
+ (GCHelper *)sharedInstance
{
    if(!sharedHelper)
    {
        sharedHelper = [[GCHelper alloc] init];
    }
    
    return sharedHelper;
}

- (BOOL)isGameCenterAvailable
{
    // Check for presence of GKLocalPlayer API
    Class gcClass = (NSClassFromString(@"GKLocalPlayer"));
    
    // Check if the device is running iOS 4.1 or later
    NSString *reqSysVer = @"4.1";
    NSString *curSysVer = [[UIDevice currentDevice] systemVersion];
    BOOL osVersionSupported = ([curSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending);
    
    return (gcClass && osVersionSupported);
}

- (id)init
{
    if((self = [super init]))
    {
        gameCenterAvailable = [self isGameCenterAvailable];
        if(gameCenterAvailable)
        {
            NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
            [nc addObserver:self 
                   selector:@selector(authenticationChanged) 
                       name:GKPlayerAuthenticationDidChangeNotificationName 
                     object:nil];
            
            displayedGCLoginError = NO;
            stopGCDialogues = NO;
            matchPushed = NO;
        }
    }
    
    return self;
}

- (void)authenticationChanged
{
    if([GKLocalPlayer localPlayer].isAuthenticated && !userAuthenticated)
    {
        NSLog(@"Authentication Changed: player authenticated.");
        userAuthenticated = TRUE;
    }
    else if (![GKLocalPlayer localPlayer].isAuthenticated && userAuthenticated) 
    {
        NSLog(@"Authentication Changed: player not authenticated.");
        userAuthenticated = FALSE;
    }
}

#pragma mark - UIAlertViewDelegate Methods

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"5.0") && SYSTEM_VERSION_LESS_THAN(@"6.0"))
    {
        void (^setGKEventHandlerDelegate)(NSError*) = ^ (NSError *error)
        {
            GKTurnBasedEventHandler *ev = [GKTurnBasedEventHandler sharedTurnBasedEventHandler];
            ev.delegate = self;
            
            if(error)
            {
                NSLog(@"%@", error);
                switch (error.code)
                {
                    case GKErrorUnknown:
                        // Shouldn't happen
                        break;
                        
                    case GKErrorCancelled:
                    {
                        if(displayedGCLoginError == NO)
                        {
                            // The GC login dialogue was cancelled, but it is required that a user log in.
                            UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Game Center Required!" message:@"Skittykitts uses Game Center Multiplayer, so in order to play you must sign in with Game Center." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
                            [av show];
                            [av release];
                            displayedGCLoginError = YES;
                        }
                        else
                        {
                            UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Game Center Disabled!" message:@"Open Game Center app and log in in order to enable multiplayer features." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
                            [av show];
                            [av release];
                            stopGCDialogues = YES;
                        }
                        
                        break;
                    }
                        
                    case GKErrorNotAuthenticated:
                    {
                        if(displayedGCLoginError == NO)
                        {
                            // The GC login dialogue was cancelled, but it is required that a user log in.
                            UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Game Center Required!" message:@"Skittykitts uses Game Center Multiplayer, so in order to play you must sign in with Game Center." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
                            [av show];
                            [av release];
                            displayedGCLoginError = YES;
                        }
                        else
                        {
                            UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Game Center Disabled!" message:@"Open Game Center app and log in in order to enable multiplayer features." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
                            [av show];
                            [av release];
                            stopGCDialogues = YES;
                        }
                        
                        break;
                    }
                        
                    default:
                        break;
                }
            }
        };
        
        if(stopGCDialogues == NO)
            [[GKLocalPlayer localPlayer] authenticateWithCompletionHandler:setGKEventHandlerDelegate];
    }
    else if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0"))
    {
        GKTurnBasedEventHandler *ev = [GKTurnBasedEventHandler sharedTurnBasedEventHandler];
        ev.delegate = self;
        
        GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
        localPlayer.authenticateHandler = ^(UIViewController *viewController, NSError *error)
        {
            if (viewController != nil)
            {
                AppController *appDelegate = (AppController*)[UIApplication sharedApplication].delegate;
                //[[GCHelper sharedInstance] findMatchWithMinPlayers:2 maxPlayers:4 viewController:delegate.navController];
                
                //[self showAuthenticationDialogWhenReasonable: viewController];
                [appDelegate.navController presentViewController:viewController animated:YES completion:^(void)
                 {
                     
                 }];
            }
            else if (localPlayer.isAuthenticated)
            {
                //int i = 0;
                //[self authenticatedPlayer: localPlayer];
            }
            else
            {
                UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Game Center Disabled!" message:@"Open Game Center app and log in in order to enable multiplayer features." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
                [av show];
                [av release];
                stopGCDialogues = YES;
                //[self disableGameCenter];
            }
        };
    }
}

#pragma mark - User Methods

- (void)authenticateLocalUser
{
    if(!gameCenterAvailable)
        return;
    
    //NSString *osVersion = [[UIDevice currentDevice] systemVersion];
    
    if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"5.0") && SYSTEM_VERSION_LESS_THAN(@"6.0"))
    {
        
        void (^setGKEventHandlerDelegate)(NSError*) = ^ (NSError *error)
        {
            GKTurnBasedEventHandler *ev = [GKTurnBasedEventHandler sharedTurnBasedEventHandler];
            ev.delegate = self;
            
            if(error)
            {
                NSLog(@"%@", error);
                switch (error.code)
                {
                    case GKErrorUnknown:
                        // Shouldn't happen
                        break;
                        
                    case GKErrorCancelled:
                    {
                        if(displayedGCLoginError == NO)
                        {
                            // The GC login dialogue was cancelled, but it is required that a user log in.
                            UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Game Center Required!" message:@"Skittykitts uses Game Center Multiplayer, so in order to play you must sign in with Game Center." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
                            [av show];
                            [av release];
                            displayedGCLoginError = YES;
                        }
                        else
                        {
                            UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Game Center Disabled!" message:@"Open Game Center app and log in in order to enable multiplayer features." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
                            [av show];
                            [av release];
                            stopGCDialogues = YES;
                        }
                        
                        break;
                    }
                        
                    case GKErrorNotAuthenticated:
                    {
                        if(displayedGCLoginError == NO)
                        {
                            // The GC login dialogue was cancelled, but it is required that a user log in.
                            UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Game Center Required!" message:@"Skittykitts uses Game Center Multiplayer, so in order to play you must sign in with Game Center." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
                            [av show];
                            [av release];
                            displayedGCLoginError = YES;
                        }
                        else
                        {
                            UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Game Center Disabled!" message:@"Open Game Center app and log in in order to enable multiplayer features." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
                            [av show];
                            [av release];
                            stopGCDialogues = YES;
                        }
                        
                        break;
                    }
                        
                    default:
                        break;
                }
            }
        };
        
        NSLog(@"Authenticating local user...");
        if([GKLocalPlayer localPlayer].authenticated == NO)
        {
            [[GKLocalPlayer localPlayer] authenticateWithCompletionHandler:setGKEventHandlerDelegate];
            
            // Uncomment to clear all matches from current Game Center user's match queue.
            //        [[GKLocalPlayer localPlayer] authenticateWithCompletionHandler:^(NSError *error)
            //         {
            //             [GKTurnBasedMatch loadMatchesWithCompletionHandler:^(NSArray *matches, NSError *error)
            //              {
            //                  for(GKTurnBasedMatch *match in matches)
            //                  {
            //                      NSLog(@"%@", match.matchID);
            //                      [match removeWithCompletionHandler:^(NSError *error)
            //                       {
            //                           NSLog(@"%@", error);
            //                       }];
            //                  }
            //              }]
            //         }];
        }
        else 
        {
            NSLog(@"Already authenticated.");
            setGKEventHandlerDelegate(nil);
        }
    }
    else if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0"))
    {
        GKTurnBasedEventHandler *ev = [GKTurnBasedEventHandler sharedTurnBasedEventHandler];
        ev.delegate = self;
        
        GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
        localPlayer.authenticateHandler = ^(UIViewController *viewController, NSError *error)
        {
            if (viewController != nil)
            {
                AppController *appDelegate = (AppController*)[UIApplication sharedApplication].delegate;
                //[[GCHelper sharedInstance] findMatchWithMinPlayers:2 maxPlayers:4 viewController:delegate.navController];
                
                //[self showAuthenticationDialogWhenReasonable: viewController];
                [appDelegate.navController presentViewController:viewController animated:YES completion:^(void)
                 {
                     
                 }];
            }
            else if (localPlayer.isAuthenticated)
            {
                //int i = 0;
                //[self authenticatedPlayer: localPlayer];
            }
            else
            {
                UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Game Center Disabled!" message:@"Open Game Center app and log in in order to enable multiplayer features." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
                [av show];
                [av release];
                stopGCDialogues = YES;
                //[self disableGameCenter];
            }
        };
    }
}

- (void)findMatchWithMinPlayers:(uint)minPlayers 
                     maxPlayers:(uint)maxPlayers
                 viewController:(UIViewController *)viewController
{
    if(!gameCenterAvailable)
        return;
    
    presentingViewController = viewController;
    
    GKMatchRequest *request = [[GKMatchRequest alloc] init];
    request.minPlayers = minPlayers;
    request.maxPlayers = maxPlayers;
    
    GKTurnBasedMatchmakerViewController *mmvc = [[GKTurnBasedMatchmakerViewController alloc] initWithMatchRequest:request];
    mmvc.turnBasedMatchmakerDelegate = self;
    mmvc.showExistingMatches = YES;
    
    [presentingViewController presentModalViewController:mmvc animated:YES];
}

#pragma mark - GKTurnBasedMatchmakerViewControllerDelegate Methods

- (void)turnBasedMatchmakerViewController:(GKTurnBasedMatchmakerViewController *)viewController didFindMatch:(GKTurnBasedMatch *)match
{
    [presentingViewController dismissModalViewControllerAnimated:YES];
    //[presentingViewController.view.superview removeFromSuperview];
    
    self.currentMatch = match;
    
    GKTurnBasedParticipant *firstParticipant = [match.participants objectAtIndex:0];
    if(firstParticipant.lastTurnDate == NULL)
    {
        // It's a new game!
        [delegate enterNewGame:match];
    }
    else
    {
        if([match.currentParticipant.playerID isEqualToString:[GKLocalPlayer localPlayer].playerID])
        {
            // It's your turn
            [delegate takeTurn:match];
        }
        else
        {
            // It's not your turn, just display the game state
            [delegate layoutMatch:match];
        }
    }
    
    NSLog(@"Current match: %@", match);
}

- (void)turnBasedMatchmakerViewControllerWasCancelled:(GKTurnBasedMatchmakerViewController *)viewController
{
    [presentingViewController dismissModalViewControllerAnimated:YES];
    //[presentingViewController.view.superview removeFromSuperview];
    NSLog(@"Matchmaker view controller cancelled");
}

- (void)turnBasedMatchmakerViewController:(GKTurnBasedMatchmakerViewController *)viewController didFailWithError:(NSError *)error
{
    [presentingViewController dismissModalViewControllerAnimated:YES];
    //[presentingViewController.view.superview removeFromSuperview];
    NSLog(@"Error finding match: %@", error.localizedDescription);
}

- (void)turnBasedMatchmakerViewController:(GKTurnBasedMatchmakerViewController *)viewController playerQuitForMatch:(GKTurnBasedMatch *)match
{
    NSUInteger currentIndex = [match.participants indexOfObject:match.currentParticipant];
    GKTurnBasedParticipant *participant;
    
    for(int i = 0; i < [match.participants count]; ++i)
    {
        participant = [match.participants objectAtIndex:(currentIndex + 1 + i) % match.participants.count];
        if(participant.matchOutcome != GKTurnBasedMatchOutcomeQuit)
        {
            break;
        }
    }
    
    NSLog(@"Player quit for match: %@, %@", match, match.currentParticipant);
    
    [match participantQuitInTurnWithOutcome:GKTurnBasedMatchOutcomeQuit nextParticipant:participant matchData:match.matchData completionHandler:nil];
}

#pragma mark - GKTurnBasedEventHandlerDelegate Methods

- (void)handleInviteFromGameCenter:(NSArray *)playersToInvite
{
    NSLog(@"New game invite.");
    
    [presentingViewController dismissModalViewControllerAnimated:YES];
    //[presentingViewController.view.superview removeFromSuperview];
    GKMatchRequest *request = [[[GKMatchRequest alloc] init] autorelease];
    request.playersToInvite = playersToInvite;
    request.maxPlayers = 4;
    request.minPlayers = 2;
    GKTurnBasedMatchmakerViewController *viewController = [[GKTurnBasedMatchmakerViewController alloc] initWithMatchRequest:request];
    viewController.showExistingMatches = NO;
    viewController.turnBasedMatchmakerDelegate = self;
    [presentingViewController presentModalViewController:viewController animated:YES];
}

- (void)handleTurnEventForMatch:(GKTurnBasedMatch *)match didBecomeActive:(BOOL)didBecomeActive
{
    NSLog(@"Turn has happened.");
    
//    if(didBecomeActive)
//    {
//        matchPushed = YES;
//    }
//    else
//    {
//        matchPushed = NO;
//    }
    
    if([match.matchID isEqualToString:currentMatch.matchID])
    {
        if([match.currentParticipant.playerID isEqualToString:[GKLocalPlayer localPlayer].playerID])
        {
            // It's the current match and it's our turn now
            self.currentMatch = match;
            [delegate takeTurn:match];
        }
        else
        {
            // It's the current match, but it's someone else's turn
            self.currentMatch = match;
            [delegate layoutMatch:match];
        }
    }
    else
    {
        if([match.currentParticipant.playerID isEqualToString:[GKLocalPlayer localPlayer].playerID])
        {
            // It's not the current match, and it's your turn now
            [delegate sendNotice:@"It's your turn for another match" forMatch:match];
        }
        else
        {
            // It's not the current match, and it's someone else's turn
        }
    }
}

- (void)handleTurnEventForMatch:(GKTurnBasedMatch *)match
{
    NSLog(@"Turn has happened.");
    
    if([match.matchID isEqualToString:currentMatch.matchID])
    {
        if([match.currentParticipant.playerID isEqualToString:[GKLocalPlayer localPlayer].playerID])
        {
            // It's the current match and it's our turn now
            self.currentMatch = match;
            [delegate takeTurn:match];
        }
        else
        {
            // It's the current match, but it's someone else's turn
            self.currentMatch = match;
            [delegate layoutMatch:match];
        }
    }
    else
    {
        if([match.currentParticipant.playerID isEqualToString:[GKLocalPlayer localPlayer].playerID])
        {
            // It's not the current match, and it's your turn now
            [delegate sendNotice:@"It's your turn for another match" forMatch:match];
        }
        else
        {
            // It's not the current match, and it's someone else's turn
        }
    }
}

- (void)handleMatchEnded:(GKTurnBasedMatch *)match
{
    NSLog(@"Game has ended.");
    
    if([match.matchID isEqualToString:currentMatch.matchID])
    {
        [delegate recieveEndGame:match];
    }
    else
    {
        [delegate sendNotice:@"Another Game Ended!" forMatch:match];
    }
}

@end
