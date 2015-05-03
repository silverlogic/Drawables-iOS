//
//  PAPPhotoCell.m
//  Anypic
//
//  Created by Héctor Ramos on 5/3/12.
//  Copyright (c) 2013 Parse. All rights reserved.
//

#import "PAPPhotoCell.h"
#import "PAPUtility.h"
#import "AppDelegate.h"

@implementation PAPPhotoCell
@synthesize photoButton;
@synthesize redoodleButton;

#pragma mark - NSObject

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
 
    if (self) {
        // Initialization code
        self.opaque = NO;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.accessoryType = UITableViewCellAccessoryNone;
        self.clipsToBounds = NO;
        
        self.backgroundColor = [UIColor clearColor];
        
        self.imageView.frame = CGRectMake( 0.0f, 0.0f, self.bounds.size.width, self.bounds.size.width);
        self.imageView.backgroundColor = [UIColor blackColor];
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        
        self.photoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.photoButton.frame = CGRectMake( 0.0f, 0.0f, self.bounds.size.width, self.bounds.size.width);
        self.photoButton.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:self.photoButton];
		
		self.redoodleButton = [UIButton buttonWithType:UIButtonTypeCustom];
		UIImage *btnImage = [UIImage imageNamed:@"drawbar"];

		self.redoodleButton.frame = CGRectMake( 0.0f, 0.0f, self.bounds.size.width, self.bounds.size.width);
		//self.redoodleButton.frame.size = btnImage.size;
		[self.redoodleButton setImage:btnImage forState:UIControlStateNormal];
		self.redoodleButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
//		self.redoodleButton.backgroundColor = [UIColor greenColor];
		[self.redoodleButton addTarget:self action:@selector(didTapRedoodlePhotoButtonAction:) forControlEvents:UIControlEventTouchUpInside];
		
		[self.contentView addSubview:self.redoodleButton];
		
        [self.contentView bringSubviewToFront:self.imageView];
		[self.contentView bringSubviewToFront:self.redoodleButton];

    }

    return self;
}


#pragma mark - UIView

- (void)layoutSubviews {
    [super layoutSubviews];
    self.imageView.frame = CGRectMake( 0.0f, 0.0f, self.bounds.size.width, self.bounds.size.width);
    self.photoButton.frame = CGRectMake( 0.0f, 0.0f, self.bounds.size.width, self.bounds.size.width);
	self.redoodleButton.frame = CGRectMake( self.bounds.size.width - 50, 0.0f, 50, 50);
}

- (void)didTapRedoodlePhotoButtonAction:(UIButton *)button {
	AppDelegate *appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
	appDelegate.canvasViewController.backgroundImage = self.imageView.image;
	appDelegate.tabBarController.selectedIndex = 1;
}

@end
