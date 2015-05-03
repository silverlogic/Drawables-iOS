//
//  PAPLogInViewController.m
//  Anypic
//
//  Created by Mattieu Gamache-Asselin on 5/17/12.
//  Copyright (c) 2013 Parse. All rights reserved.
//

#import "PAPLogInViewController.h"
#import "AppDelegate.h"

#import "MBProgressHUD.h"

@interface PAPLogInViewController() {
    FBLoginView *_facebookLoginView;
}

@property (nonatomic, strong) MBProgressHUD *hud;

@end

@interface FBSession (Private)

- (void)clearAffinitizedThread;

@end

@implementation PAPLogInViewController

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // There is no documentation on how to handle assets with the taller iPhone 5 screen as of 9/13/2012
    //if ([UIScreen mainScreen].bounds.size.height > 480.0f) {
        // for the iPhone 5
      //  self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"BackgroundLogin-568h"]];
    //} else {
        self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"BackgroundLogin"]];
    //}
    
    //Position of the Facebook button
    CGFloat yPosition = 360.0f;
    if ([UIScreen mainScreen].bounds.size.height > 480.0f) {
        yPosition = 450.0f;
    }
    
    _facebookLoginView = [[FBLoginView alloc] initWithReadPermissions:@[@"public_profile", @"user_friends", @"email", @"user_photos"]];
    _facebookLoginView.frame = CGRectMake(36.0f, yPosition, 244.0f, 44.0f);
    _facebookLoginView.delegate = self;
    _facebookLoginView.tooltipBehavior = FBLoginViewTooltipBehaviorDisable;
    [self.view addSubview:_facebookLoginView];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return toInterfaceOrientation == UIInterfaceOrientationPortrait;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}


#pragma mark - FBLoginViewDelegate

- (void)loginViewShowingLoggedInUser:(FBLoginView *)loginView {
    [self handleFacebookSession];
}

- (void)loginView:(FBLoginView *)loginView handleError:(NSError *)error {
    [self handleLogInError:error];
}

// Call method when user information has been fetched
- (void)loginViewFetchedUserInfo:(FBLoginView *)loginView
                            user:(id<FBGraphUser>)user {
    NSLog(@"%@, %@" , user.objectID, user.name);
    [self handleLoginForUserId:user.objectID];
}

- (void)handleFacebookSession {
    if ([PFUser currentUser]) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(logInViewControllerDidLogUserIn:)]) {
            [self.delegate performSelector:@selector(logInViewControllerDidLogUserIn:) withObject:[PFUser currentUser]];
        }
        return;
    }
    
//    NSString *accessToken = [[[FBSession activeSession] accessTokenData] accessToken];
//    NSDate *expirationDate = [[[FBSession activeSession] accessTokenData] expirationDate];
    NSString *facebookUserId = [[[FBSession activeSession] accessTokenData] userID];
    
    [self handleLoginForUserId:facebookUserId];
}

- (void)handleLoginForUserId:(NSString*)userId {
    NSString *accessToken = [[[FBSession activeSession] accessTokenData] accessToken];
    NSDate *expirationDate = [[[FBSession activeSession] accessTokenData] expirationDate];
    
    if (!accessToken || !userId) {
        NSLog(@"Login failure. FB Access Token or user ID does not exist");
        return;
    }
    
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    // Unfortunately there are some issues with accessing the session provided from FBLoginView with the Parse SDK's (thread affinity)
    // Just work around this by setting the session to nil, since the relevant values will be discarded anyway when linking with Parse (permissions flag on FBAccessTokenData)
    // that we need to get back again with a refresh of the session
    if ([[FBSession activeSession] respondsToSelector:@selector(clearAffinitizedThread)]) {
        [[FBSession activeSession] performSelector:@selector(clearAffinitizedThread)];
    }
    
    [PFFacebookUtils logInWithFacebookId:userId accessToken:accessToken expirationDate:expirationDate block:^(PFUser *user, NSError *error) {
        if (!error) {
            [self.hud removeFromSuperview];
            if (self.delegate) {
                if ([self.delegate respondsToSelector:@selector(logInViewControllerDidLogUserIn:)]) {
                    [self.delegate performSelector:@selector(logInViewControllerDidLogUserIn:) withObject:user];
                }
            }
        } else {
            [self cancelLogIn:error];
        }
    }];
}


#pragma mark - ()

- (void)cancelLogIn:(NSError *)error {
    
    if (error) {
        [self handleLogInError:error];
    }
    
    [self.hud removeFromSuperview];
    [[FBSession activeSession] closeAndClearTokenInformation];
    [PFUser logOut];
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] presentLoginViewController:NO];
}

- (void)handleLogInError:(NSError *)error {
    if (error) {
        NSLog(@"Error: %@", [[error userInfo] objectForKey:@"com.facebook.sdk:ErrorLoginFailedReason"]);
        NSString *title = NSLocalizedString(@"Login Error", @"Login error title in PAPLogInViewController");
        NSString *message = NSLocalizedString(@"Something went wrong. Please try again.", @"Login error message in PAPLogInViewController");
        
        if ([[[error userInfo] objectForKey:@"com.facebook.sdk:ErrorLoginFailedReason"] isEqualToString:@"com.facebook.sdk:UserLoginCancelled"]) {
            return;
        }
        
        if (error.code == kPFErrorFacebookInvalidSession) {
            NSLog(@"Invalid session, logging out.");
            [[FBSession activeSession] closeAndClearTokenInformation];
            return;
        }
        
        if (error.code == kPFErrorConnectionFailed) {
            NSString *ok = NSLocalizedString(@"OK", @"OK");
            NSString *title = NSLocalizedString(@"Offline Error", @"Offline Error");
            NSString *message = NSLocalizedString(@"Something went wrong. Please try again.", @"Offline message");
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                            message:message
                                                           delegate:nil
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:ok, nil];
            [alert show];
            
            return;
        }
        
        NSString *ok = NSLocalizedString(@"OK", @"OK");
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                            message:message
                                                           delegate:self
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:ok, nil];
        [alertView show];
    }
}

@end