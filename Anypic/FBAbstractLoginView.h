/*
 * Copyright 2010-present Facebook.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <UIKit/UIKit.h>

#import "FBGraphUser.h"
#import "FBSession.h"

@interface FBAbstractLoginView : UIView

/*!
 @abstract
 The login behavior for the active session if the user logs in via this view

 @discussion
 The default value is FBSessionLoginBehaviorWithFallbackToWebView.
 */
@property (nonatomic) FBSessionLoginBehavior loginBehavior;

/*!
 @abstract
 Initializes and returns an `FBAbstractLoginView` object.
 */
- (instancetype)init;

@end

