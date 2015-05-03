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
