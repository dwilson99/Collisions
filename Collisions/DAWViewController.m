//
//  DAWViewController.m
//  Collisions
//
//  Created by SSD Boot Admin on 9/18/13.
//  Copyright (c) 2013 SSD Boot Admin. All rights reserved.
//

#import "DAWViewController.h"
#import "APLSpaceScene.h"

//==========================
@interface DAWViewController ()
@property (weak, nonatomic) APLSpaceScene * scene;
@end

//==========================
@implementation DAWViewController

//--------------------------
- (void)viewDidLoad {
    [super viewDidLoad];

    // Configure the view.
    SKView * skView = self.skView;
    skView.showsFPS = YES;
    skView.showsNodeCount = YES;
    
    // Create and configure the scene.
//    SKScene * scene = [DAWMyScene sceneWithSize:skView.bounds.size];
    self.scene = [APLSpaceScene sceneWithSize:skView.bounds.size];
    self.scene.scaleMode = SKSceneScaleModeAspectFill;
    
    // Present the scene.
    [skView presentScene:self.scene];
}

//--------------------------
- (BOOL)shouldAutorotate {
    return YES;
}

//--------------------------
- (NSUInteger)supportedInterfaceOrientations {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

//--------------------------
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - Actions
//--------------------------
- (IBAction)leftAction:(id)sender {
	[self.scene leftAction:sender];
}

//--------------------------
- (IBAction)forwardAction:(id)sender {
	[self.scene forwardAction:sender];
}

//--------------------------
- (IBAction)backAction:(id)sender {
	[self.scene backAction:sender];
}

//--------------------------
- (IBAction)rightAction:(id)sender {
	[self.scene rightAction:sender];
}

@end
