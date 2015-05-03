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
@property (nonatomic, assign) UIBackgroundTaskIdentifier fileUploadBackgroundTaskId;
@property (nonatomic, assign) UIBackgroundTaskIdentifier photoPostBackgroundTaskId;

@property (nonatomic, strong) NSArray *colorButtons;

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
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(takeScreenshot:)];
    
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
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

#pragma mark - Actions
- (void)updateButtonStatus
{
	self.undoButton.enabled = [self.drawingView canUndo];
	self.redoButton.enabled = [self.drawingView canRedo];
}
- (void)cameraActionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 0) {
		[self shouldStartCameraController];
	} else if (buttonIndex == 1) {
		[self shouldStartPhotoLibraryPickerController];
	}
}

- (IBAction)takeScreenshot:(id)sender
{
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
- (void)drawingView:(ACEDrawingView *)view didEndDrawUsingTool:(id<ACEDrawingTool>)tool;
{
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

#pragma mark - Action Sheet Delegate
//edit this to respond to the tool picker labels
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	self.toolButton.title = [actionSheet buttonTitleAtIndex:buttonIndex];
	switch (buttonIndex) {
		case 0:
			self.drawingView.drawTool = ACEDrawingToolTypePen;
			break;
			
		case 1:
			self.drawingView.drawTool = ACEDrawingToolTypeLine;
			break;
			
		case 2:
			self.drawingView.drawTool = ACEDrawingToolTypeRectagleStroke;
			break;
			
		case 3:
			self.drawingView.drawTool = ACEDrawingToolTypeRectagleFill;
			break;
			
		case 4:
			self.drawingView.drawTool = ACEDrawingToolTypeEllipseStroke;
			break;
			
		case 5:
			self.drawingView.drawTool = ACEDrawingToolTypeEllipseFill;
			break;
			
		case 6:
			self.drawingView.drawTool = ACEDrawingToolTypeEraser;
			break;
			
		case 7:
			self.drawingView.drawTool = ACEDrawingToolTypeText;
			break;
	}
}

#pragma mark - Settings

- (IBAction)toolChange:(id)sender
{
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Selet a tool"
															 delegate:self
													cancelButtonTitle:@"Cancel"
											   destructiveButtonTitle:nil
													otherButtonTitles:@"Pen", @"Line",
								  @"Rect (Stroke)", @"Rect (Fill)",
								  @"Ellipse (Stroke)", @"Ellipse (Fill)",
								  @"Eraser", @"Text",
								  nil];
	
	[actionSheet setTag:kActionSheetTool];
	[actionSheet showInView:self.view];
}

- (IBAction)toggleWidthSlider:(id)sender
{
	// toggle the slider
	self.lineWidthSlider.hidden = !self.lineWidthSlider.hidden;
	self.lineAlphaSlider.hidden = YES;
}

- (IBAction)widthChange:(UISlider *)sender
{
	self.drawingView.lineWidth = sender.value;
}

- (IBAction)alphaChange:(UISlider *)sender
{
	self.drawingView.lineAlpha = sender.value;
	[self matchColor];
}

@end
