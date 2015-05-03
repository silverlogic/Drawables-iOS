//
//  ACEViewController.m
//  ACEDrawingViewDemo
//
//  Created by Stefano Acerbetti on 1/6/13.
//  Copyright (c) 2013 Stefano Acerbetti. All rights reserved.
//

#import "ACEViewController.h"
#import "ACEDrawingView.h"
#import "PAPEditPhotoViewController.h"
#import "PAPPhotoDetailsFooterView.h"
#import "UIImage+ResizeAdditions.h"
#import <FBSDKMessengerShareKit/FBSDKMessengerShareKit.h>
#import "MBProgressHUD.h"

#import <QuartzCore/QuartzCore.h>

#define kActionSheetTool        101

// tagged color buttons
typedef NS_ENUM(NSUInteger, PaintColor) {
	PaintColorWhite,
	PaintColorRed,
	PaintColorOrange,
	PaintColorYellow,
	PaintColorGreen,
	PaintColorBlue,
	PaintColorRandom,
	PaintColorPurple,
	PaintColorBrown,
	PaintColorBlack
};

@interface ACEViewController ()<UIActionSheetDelegate, ACEDrawingViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) PFFile *photoFile;
@property (nonatomic, strong) PFFile *thumbnailFile;
@property (nonatomic, assign) UIBackgroundTaskIdentifier fileUploadBackgroundTaskId;
@property (nonatomic, assign) UIBackgroundTaskIdentifier photoPostBackgroundTaskId;

@property (nonatomic, strong) NSArray *colorButtons;
@property (nonatomic, strong) UIButton *shareButton;

@end

@implementation ACEViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	// set the delegate
	self.drawingView.delegate = self;
	
	// start with a black pen
	self.lineWidthSlider.value = self.drawingView.lineWidth;
	
	// init the preview image
	self.previewImageView.layer.borderColor = [[UIColor blackColor] CGColor];
	self.previewImageView.layer.borderWidth = 2.0f;
    
    // navbar buttons
    self.navigationItem.leftBarButtonItems = @[ self.undoButton, self.redoButton, self.clearButton ];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(addBackground:)];
    
    // init colors
    self.colorButtons = @[
                          self.red,
                          self.orange,
                          self.yellow,
                          self.green,
                          self.blue,
                          self.purple,
//                          self.random,
                          self.brown,
                          self.black
                          ];
    for (UIButton *button in self.colorButtons) {
        button.backgroundColor = [self colorForPaintColor:button.tag];
    }
    
    // init share button
    
    //Define the size of the circular button at creation time
    CGFloat buttonWidth = 50;
    CGFloat padding = 5.0f;
    CGFloat buttonHeight = self.tabBarController.tabBar.bounds.size.height - padding;
    self.shareButton = [FBSDKMessengerShareButton circularButtonWithStyle:FBSDKMessengerShareButtonStyleBlue width:buttonWidth];
    self.shareButton.frame = CGRectMake( self.tabBarController.tabBar.bounds.size.width / 2.0f - buttonHeight / 2.0f, padding / 2.0f, buttonHeight, buttonHeight);
    [self.shareButton addTarget:self action:@selector(savePressed) forControlEvents:UIControlEventTouchUpInside];
    [self.tabBarController.tabBar addSubview:self.shareButton];
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.shareButton.hidden = NO;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    self.shareButton.hidden = YES;
}

#pragma mark - Actions
- (void)updateButtonStatus
{
	self.undoButton.enabled = [self.drawingView canUndo];
	self.redoButton.enabled = [self.drawingView canRedo];
}

- (IBAction)addBackground:(id)sender {
	BOOL cameraDeviceAvailable = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
	BOOL photoLibraryAvailable = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary];
	
	if (cameraDeviceAvailable && photoLibraryAvailable) {
		UIActionSheet *cameraSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Take Photo", @"Choose Photo", nil];
		[cameraSheet showFromTabBar:self.tabBarController.tabBar];
	} else {
		// if we don't have at least two options, we automatically show whichever is available (camera or roll)
		[self shouldPresentPhotoCaptureController];
	}
}

- (void)savePressed {
    [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    [self shareWithMessenger];
    [self shouldUploadImage:self.drawingView.image];
    [self clear:nil];
    [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
}

- (void)shareWithMessenger {
    if ([FBSDKMessengerSharer messengerPlatformCapabilities] & FBSDKMessengerPlatformCapabilityImage) {
        [FBSDKMessengerSharer shareImage:self.drawingView.image withOptions:nil];
    }
}

- (void)saveToBackend {
    NSDictionary *userInfo = [NSDictionary dictionary];
    NSString *trimmedComment = nil; //[self.commentTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (trimmedComment.length != 0) {
        userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                    trimmedComment,kPAPEditPhotoViewControllerUserInfoCommentKey,
                    nil];
    }
    
    if (!self.photoFile || !self.thumbnailFile) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Couldn't post your photo" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Dismiss", nil];
        [alert show];
        return;
    }
    
    // both files have finished uploading
    
    // create a photo object
    PFObject *photo = [PFObject objectWithClassName:kPAPPhotoClassKey];
    [photo setObject:[PFUser currentUser] forKey:kPAPPhotoUserKey];
    [photo setObject:self.photoFile forKey:kPAPPhotoPictureKey];
    [photo setObject:self.thumbnailFile forKey:kPAPPhotoThumbnailKey];
    
    // photos are public, but may only be modified by the user who uploaded them
    PFACL *photoACL = [PFACL ACLWithUser:[PFUser currentUser]];
    [photoACL setPublicReadAccess:YES];
    photo.ACL = photoACL;
    
    // Request a background execution task to allow us to finish uploading the photo even if the app is backgrounded
    self.photoPostBackgroundTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:self.photoPostBackgroundTaskId];
    }];
    
    // save
    [photo saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            NSLog(@"Photo uploaded");
            
            [[PAPCache sharedCache] setAttributesForPhoto:photo likers:[NSArray array] commenters:[NSArray array] likedByCurrentUser:NO];
            
            // userInfo might contain any caption which might have been posted by the uploader
            if (userInfo) {
                NSString *commentText = [userInfo objectForKey:kPAPEditPhotoViewControllerUserInfoCommentKey];
                
                if (commentText && commentText.length != 0) {
                    // create and save photo caption
                    PFObject *comment = [PFObject objectWithClassName:kPAPActivityClassKey];
                    [comment setObject:kPAPActivityTypeComment forKey:kPAPActivityTypeKey];
                    [comment setObject:photo forKey:kPAPActivityPhotoKey];
                    [comment setObject:[PFUser currentUser] forKey:kPAPActivityFromUserKey];
                    [comment setObject:[PFUser currentUser] forKey:kPAPActivityToUserKey];
                    [comment setObject:commentText forKey:kPAPActivityContentKey];
                    
                    PFACL *ACL = [PFACL ACLWithUser:[PFUser currentUser]];
                    [ACL setPublicReadAccess:YES];
                    comment.ACL = ACL;
                    
                    [comment saveEventually];
                    [[PAPCache sharedCache] incrementCommentCountForPhoto:photo];
                }
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:PAPTabBarControllerDidFinishEditingPhotoNotification object:photo];
        } else {
            NSLog(@"Photo failed to save: %@", error);
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Couldn't post your photo" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Dismiss", nil];
            [alert show];
        }
        [[UIApplication sharedApplication] endBackgroundTask:self.photoPostBackgroundTaskId];
    }];
}

- (BOOL)shouldUploadImage:(UIImage *)anImage {
    UIImage *resizedImage = [anImage resizedImageWithContentMode:UIViewContentModeScaleAspectFit bounds:CGSizeMake(560.0f, 560.0f) interpolationQuality:kCGInterpolationHigh];
    UIImage *thumbnailImage = [anImage thumbnailImage:86.0f transparentBorder:0.0f cornerRadius:10.0f interpolationQuality:kCGInterpolationDefault];
    
    // JPEG to decrease file size and enable faster uploads & downloads
    NSData *imageData = UIImageJPEGRepresentation(resizedImage, 0.8f);
    NSData *thumbnailImageData = UIImagePNGRepresentation(thumbnailImage);
    
    if (!imageData || !thumbnailImageData) {
        return NO;
    }
    
    self.photoFile = [PFFile fileWithData:imageData];
    self.thumbnailFile = [PFFile fileWithData:thumbnailImageData];
    
    // Request a background execution task to allow us to finish uploading the photo even if the app is backgrounded
    self.fileUploadBackgroundTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:self.fileUploadBackgroundTaskId];
    }];
    
    NSLog(@"Requested background expiration task with id %lu for Anypic photo upload", (unsigned long)self.fileUploadBackgroundTaskId);
    [self.photoFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            NSLog(@"Photo uploaded successfully");
            [self saveToBackend];
            [self.thumbnailFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    NSLog(@"Thumbnail uploaded successfully");
                }
                [[UIApplication sharedApplication] endBackgroundTask:self.fileUploadBackgroundTaskId];
            }];
        } else {
            [[UIApplication sharedApplication] endBackgroundTask:self.fileUploadBackgroundTaskId];
        }
    }];
    
    return YES;
}
- (IBAction)usePen:(id)sender {
	self.drawingView.drawTool = ACEDrawingToolTypePen;
	self.drawingView.lineWidth = 6;
	self.drawingView.lineAlpha = 1;
	[self matchColor];
}

- (IBAction)usePencil:(id)sender {
	self.drawingView.drawTool = ACEDrawingToolTypePen;
	self.drawingView.lineWidth = 3;
	self.drawingView.lineAlpha = .75;
	[self matchColor];
}

- (IBAction)useBrush:(id)sender {
	self.drawingView.drawTool = ACEDrawingToolTypePen;
	self.drawingView.lineWidth = 20;
	self.drawingView.lineAlpha = .5;
	[self matchColor];
}

- (IBAction)useEraser:(id)sender {
	self.drawingView.drawTool = ACEDrawingToolTypeEraser;
}

- (BOOL)shouldPresentPhotoCaptureController {
	BOOL presentedPhotoCaptureController = [self shouldStartCameraController];
	
	if (!presentedPhotoCaptureController) {
		presentedPhotoCaptureController = [self shouldStartPhotoLibraryPickerController];
	}
	
	return presentedPhotoCaptureController;
}

- (BOOL)shouldStartPhotoLibraryPickerController {
	if (([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary] == NO
		 && [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum] == NO)) {
		return NO;
	}
	
	UIImagePickerController *cameraUI = [[UIImagePickerController alloc] init];
	if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]
		&& [[UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypePhotoLibrary] containsObject:(NSString *)kUTTypeImage]) {
		
		cameraUI.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
		cameraUI.mediaTypes = [NSArray arrayWithObject:(NSString *) kUTTypeImage];
		
	} else if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum]
			   && [[UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeSavedPhotosAlbum] containsObject:(NSString *)kUTTypeImage]) {
		
		cameraUI.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
		cameraUI.mediaTypes = [NSArray arrayWithObject:(NSString *) kUTTypeImage];
		
	} else {
		return NO;
	}
	
	cameraUI.allowsEditing = YES;
	cameraUI.delegate = self;
	
	[self presentViewController:cameraUI animated:YES completion:nil];
	
	return YES;
}

- (BOOL)shouldStartCameraController {
	
	if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == NO) {
		return NO;
	}
	
	UIImagePickerController *cameraUI = [[UIImagePickerController alloc] init];
	
	if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]
		&& [[UIImagePickerController availableMediaTypesForSourceType:
			 UIImagePickerControllerSourceTypeCamera] containsObject:(NSString *)kUTTypeImage]) {
		
		cameraUI.mediaTypes = [NSArray arrayWithObject:(NSString *) kUTTypeImage];
		cameraUI.sourceType = UIImagePickerControllerSourceTypeCamera;
		
		if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear]) {
			cameraUI.cameraDevice = UIImagePickerControllerCameraDeviceRear;
		} else if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront]) {
			cameraUI.cameraDevice = UIImagePickerControllerCameraDeviceFront;
		}
		
	} else {
		return NO;
	}
	
	cameraUI.allowsEditing = YES;
	cameraUI.showsCameraControls = YES;
	cameraUI.delegate = self;
	
	[self presentViewController:cameraUI animated:YES completion:nil];
	
	return YES;
}


- (IBAction)undo:(id)sender
{
	[self.drawingView undoLatestStep];
	[self updateButtonStatus];
}

- (IBAction)redo:(id)sender
{
	[self.drawingView redoLatestStep];
	[self updateButtonStatus];
}

- (IBAction)clear:(id)sender
{
	[self.drawingView clear];
	[self updateButtonStatus];
}

#pragma mark - UIImagePickerDelegate

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	
	UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
	
	PAPEditPhotoViewController *viewController = [[PAPEditPhotoViewController alloc] initWithImage:image];
	[viewController setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];
	
	[self setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];
	
	[self dismissViewControllerAnimated:YES completion:^{
		[self.drawingView loadImage:image];
	}];
}

#pragma mark - ACEDrawing View Delegate
//edit this to respond to the tool picker labels
- (void)drawingView:(ACEDrawingView *)view didEndDrawUsingTool:(id<ACEDrawingTool>)tool {
	[self updateButtonStatus];
}

- (void)matchColor {
	self.current.alpha = self.drawingView.lineAlpha;
	self.current.backgroundColor = self.drawingView.lineColor;
}

- (IBAction)colorUpdate:(UIButton *)sender {
    self.drawingView.lineColor = [self colorForPaintColor:sender.tag];
    [self matchColor];
}

- (UIColor*)colorForPaintColor:(PaintColor)paintColor {
    switch (paintColor) {
        case PaintColorWhite:
            return [UIColor whiteColor];
        case PaintColorRed:
            return [UIColor redColor];
        case PaintColorOrange:
            return [UIColor orangeColor];
        case PaintColorYellow:
            return [UIColor yellowColor];
        case PaintColorGreen:
            return [UIColor greenColor];
        case PaintColorBlue:
            return [UIColor blueColor];
        case PaintColorRandom:
            return [UIColor colorWithHue:((rand()%256)/256.0) saturation:((rand()%256)/256.0) brightness:((rand()%256)/256.0) alpha:1];
        case PaintColorPurple:
            return [UIColor purpleColor];
        case PaintColorBrown:
            return [UIColor brownColor];
        case PaintColorBlack:
            return [UIColor blackColor];
        default:
            return [UIColor blackColor];
    }
}

- (IBAction)toggleWidthSlider:(id)sender {
	// toggle the slider
	self.lineWidthSlider.hidden = !self.lineWidthSlider.hidden;
	self.lineAlphaSlider.hidden = YES;
}

- (IBAction)widthChange:(UISlider *)sender {
	self.drawingView.lineWidth = sender.value;
}

- (IBAction)alphaChange:(UISlider *)sender {
	self.drawingView.lineAlpha = sender.value;
	[self matchColor];
}

@end
