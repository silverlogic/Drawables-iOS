//
//  PAPImageView.h
//  Anypic
//
//  Created by Mattieu Gamache-Asselin on 5/14/12.
//  Copyright (c) 2013 Parse. All rights reserved.
//

@interface PAPImageView : UIImageView

@property (nonatomic, strong) UIImage *placeholderImage;

- (void) setFile:(PFFile *)file;

@end
