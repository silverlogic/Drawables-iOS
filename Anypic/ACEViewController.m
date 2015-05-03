//
//  ACEViewController.m
//  ACEDrawingViewDemo
//
//  Created by Stefano Acerbetti on 1/6/13.
//  Copyright (c) 2013 Stefano Acerbetti. All rights reserved.
//

#import "ACEViewController.h"
#import "ACEDrawingView.h"

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

@interface ACEViewController ()<UIActionSheetDelegate, ACEDrawingViewDelegate>

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

- (IBAction)takeScreenshot:(id)sender
{
	// send image logic here
	
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

- (IBAction)colorUpdate:(UIButton *)sender;{
	switch (sender.tag) {
			
		case PaintColorWhite:
			self.drawingView.lineColor = [UIColor whiteColor];
			break;
		case PaintColorRed:
			self.drawingView.lineColor = [UIColor redColor];
			break;
		case PaintColorOrange:
			self.drawingView.lineColor = [UIColor orangeColor];
			break;
		case PaintColorYellow:
			self.drawingView.lineColor = [UIColor yellowColor];
			break;
		case PaintColorGreen:
			self.drawingView.lineColor = [UIColor greenColor];
			break;
		case PaintColorBlue:
			self.drawingView.lineColor = [UIColor blueColor];
			break;
		case PaintColorRandom:
			self.drawingView.lineColor = [UIColor colorWithHue:((rand()%256)/256.0) saturation:((rand()%256)/256.0) brightness:((rand()%256)/256.0) alpha:1];
			break;
		case PaintColorPurple:
			self.drawingView.lineColor = [UIColor purpleColor];
			break;
		case PaintColorBrown:
			self.drawingView.lineColor = [UIColor brownColor];
			break;
		case PaintColorBlack:
			self.drawingView.lineColor = [UIColor blackColor];
			break;
		default:
			self.drawingView.lineColor = [UIColor blackColor];
			break;
	}
	[self matchColor];
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
