//
//  ACEViewController.h
//  ACEDrawingViewDemo
//
//  Created by Stefano Acerbetti on 1/6/13.
//  Copyright (c) 2013 Stefano Acerbetti. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ACEDrawingView;


@interface ACEViewController : UIViewController

@property (nonatomic, unsafe_unretained) IBOutlet ACEDrawingView *drawingView;
@property (nonatomic, unsafe_unretained) IBOutlet UISlider *lineWidthSlider;
@property (nonatomic, unsafe_unretained) IBOutlet UISlider *lineAlphaSlider;
@property (nonatomic, unsafe_unretained) IBOutlet UIImageView *previewImageView;

@property (nonatomic, unsafe_unretained) IBOutlet UIBarButtonItem *undoButton;
@property (nonatomic, unsafe_unretained) IBOutlet UIBarButtonItem *redoButton;
@property (unsafe_unretained, nonatomic) IBOutlet UIBarButtonItem *clearButton;

// current color
@property (weak, nonatomic) IBOutlet UILabel *current;

// color buttons
@property (weak, nonatomic) IBOutlet UIButton *red;
@property (weak, nonatomic) IBOutlet UIButton *orange;
@property (weak, nonatomic) IBOutlet UIButton *yellow;
@property (weak, nonatomic) IBOutlet UIButton *green;
@property (weak, nonatomic) IBOutlet UIButton *blue;
@property (weak, nonatomic) IBOutlet UIButton *purple;
@property (weak, nonatomic) IBOutlet UIButton *random;
@property (weak, nonatomic) IBOutlet UIButton *brown;
@property (weak, nonatomic) IBOutlet UIButton *black;

// new tool actions - Keep

// actions
- (BOOL)shouldPresentPhotoCaptureController;
- (IBAction)undo:(id)sender;
- (IBAction)redo:(id)sender;
- (IBAction)clear:(id)sender;
- (IBAction)addBackground:(id)sender;
- (IBAction)usePen:(id)sender;
- (IBAction)usePencil:(id)sender;
- (IBAction)useBrush:(id)sender;
- (IBAction)useEraser:(id)sender;

// settings
- (IBAction)widthChange:(UISlider *)sender;
- (IBAction)alphaChange:(UISlider *)sender;

@end
