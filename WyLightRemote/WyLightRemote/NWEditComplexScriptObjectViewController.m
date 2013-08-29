//
//  NWEditComplexScriptObjectViewController.m
//  WyLightRemote
//
//  Created by Nils Weiß on 15.08.13.
//  Copyright (c) 2013 Nils Weiß. All rights reserved.
//

#import "NWEditComplexScriptObjectViewController.h"
#import "NWScriptObjectView.h"
#import "NWSetFadeScriptCommandObject.h"
#import "NWSetGradientScriptCommandObject.h"
#import "NWEditFadeCommandViewController.h"
#import "NWEditGradientCommandViewController.h"
#import "WCWiflyControlWrapper.h"
#import "NWCollectionViewLayout.h"
#import "NWScriptObjectCollectionViewCell.h"

@interface NWEditComplexScriptObjectViewController ()
@property (nonatomic, strong) NWScriptObjectView *gradientPreviewView;
@property (nonatomic, strong) UISwitch *modeSwitch;
@property (nonatomic) BOOL isDeletionModeActive;
@property (nonatomic) NSUInteger indexOfObjectToAlter;
@property (nonatomic, strong) UIButton *sendButton;
@property (nonatomic, strong) UIButton *addCommandButton;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) ALRadialMenu *radialMenu;
@property (nonatomic, weak) NSIndexPath *indexPathOfLastCell;
@end

@implementation NWEditComplexScriptObjectViewController

- (void)viewWillLayoutSubviews {
	[super viewWillLayoutSubviews];
	[self fixLocations];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.modeSwitch.on = !self.command.isWaitCommand;
	[self updateGradientView];
}

- (void)updateGradientView {
	if (self.command.prev) {
		self.gradientPreviewView.startColors = self.command.prev.colors;
	} else {
		self.gradientPreviewView.startColors = nil;
	}

	if (self.command.isWaitCommand) {
		self.gradientPreviewView.endColors = self.gradientPreviewView.startColors;
	} else {
		self.gradientPreviewView.endColors = self.command.colors;
	}
}

- (void)fixLocations {
	CGFloat totalWidth = self.view.bounds.size.width - 40.0;
	CGFloat totalHeight = self.view.bounds.size.height - 40.0;
	CGFloat xOffset = 20;
	
	if (self.view.bounds.size.height > self.view.bounds.size.width) {   //horizontal
		self.gradientPreviewView.frame = CGRectMake(xOffset, 80, totalWidth, self.command.colors.count * 5);
	
		self.modeSwitch.frame = CGRectMake(20, 20, 40, 20);

		self.collectionView.frame = CGRectMake(0, totalHeight / 2 + 100 , self.view.bounds.size.width, self.command.colors.count * 4);
	
		self.sendButton.frame = CGRectMake(140, 20, 100, 40);
		
		self.addCommandButton.frame = CGRectMake(self.view.bounds.size.width - 20, self.collectionView.center.y - 10, 20, 20);
	}
	else {
		self.gradientPreviewView.frame = CGRectMake(self.view.center.x, 20, self.view.bounds.size.width / 2 - 20, self.command.colors.count * 3);
		
		self.modeSwitch.frame = CGRectMake(20, 20, 40, 20);
		
		self.collectionView.frame = CGRectMake(0, self.view.center.y, self.view.bounds.size.width, self.command.colors.count * 4);
		
		self.sendButton.frame = CGRectMake(20, 60, 100, 40);
		
		self.addCommandButton.frame = CGRectMake(self.view.bounds.size.width - 20, self.collectionView.center.y - 10, 20, 20);
	}
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	//TESTCODE
	self.command = [[NWComplexScriptCommandObject alloc] init];
	//self.command.backgroundColor = [UIColor blackColor];
	
	{
		NWSetFadeScriptCommandObject *obj = [[NWSetFadeScriptCommandObject alloc] init];
		obj.address = 0xffffffff;
		obj.color = [UIColor redColor];
	
		[self.command.itsScriptObjects addObject:obj];
	}
	{
		NWSetFadeScriptCommandObject *obj = [[NWSetFadeScriptCommandObject alloc] init];
		obj.address = 0x000000ff;
		obj.color = [UIColor yellowColor];
		
		[self.command.itsScriptObjects addObject:obj];
	}
	{
		NWSetGradientScriptCommandObject *obj = [[NWSetGradientScriptCommandObject alloc] init];
		obj.color1 = [UIColor blueColor];
		obj.color2 = [UIColor greenColor];
	
		obj.offset = 10;
		obj.numberOfLeds = 10;
		[self.command.itsScriptObjects addObject: obj];
	}
	{
		NWSetGradientScriptCommandObject *obj = [[NWSetGradientScriptCommandObject alloc] init];
		obj.color1 = [UIColor blueColor];
		obj.color2 = [UIColor greenColor];
		
		obj.offset = 20;
		obj.numberOfLeds = 5;
		[self.command.itsScriptObjects addObject: obj];
	}
	self.command.duration = 2;
	[self setup];
}

- (void)setup {
	//self
	self.view.backgroundColor = [UIColor viewFlipsideBackgroundColor];
	
	//mode switch
	self.modeSwitch = [[UISwitch alloc]initWithFrame:CGRectZero];
	[self.modeSwitch addTarget:self action:@selector(switchChanged) forControlEvents:UIControlEventValueChanged];
	[self.view addSubview:self.modeSwitch];
	
	//gradient view
	self.gradientPreviewView = [[NWScriptObjectView alloc]initWithFrame:CGRectZero];
	self.gradientPreviewView.backgroundColor = [UIColor blackColor];
	[self.view addSubview:self.gradientPreviewView];
	
	//collection view
	NWCollectionViewLayout *layout = [[NWCollectionViewLayout alloc]init];
		
	self.collectionView = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:layout];
	self.collectionView.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
	self.collectionView.dataSource = self;
	self.collectionView.delegate = self;
	[self.collectionView registerClass:[NWScriptObjectCollectionViewCell class] forCellWithReuseIdentifier:@"SCRIPT"];
	[self.view addSubview:self.collectionView];
	
	UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(activateDeletionMode:)];
	longPress.delegate = self;
	[self.collectionView addGestureRecognizer:longPress];
	
	UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(endDeletionMode:)];
	tap.delegate = self;
	tap.numberOfTapsRequired = 1;
	[self.collectionView addGestureRecognizer:tap];
	
	//send button
	self.sendButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	[self.sendButton addTarget:self action:@selector(sendPreview:) forControlEvents:UIControlEventTouchUpInside];
	[self.sendButton setTitle:@"Preview" forState:UIControlStateNormal];
	[self.view addSubview:self.sendButton];
	
	//add command button
	self.addCommandButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
	[self.addCommandButton addTarget:self action:@selector(addCommandButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
	[self.addCommandButton setTitle:@"Add" forState:UIControlStateNormal];
	[self.view addSubview:self.addCommandButton];

	//radial menue
	self.radialMenu = [[ALRadialMenu alloc] init];
	self.radialMenu.delegate = self;
}

#pragma mark - RADIAL MENU DELEGATE 
- (NSInteger)numberOfItemsInRadialMenu:(ALRadialMenu *)radialMenu {
	return 2;
}

- (NSInteger)arcStartForRadialMenu:(ALRadialMenu *)radialMenu {
	return 145;
}

- (NSInteger)arcSizeForRadialMenu:(ALRadialMenu *)radialMenu {
	return 70;
}

- (NSInteger)arcRadiusForRadialMenu:(ALRadialMenu *)radialMenu {
	return 60;
}

- (float)buttonSizeForRadialMenu:(ALRadialMenu *)radialMenu {
	return 50;
}

- (UIImage *)radialMenu:(ALRadialMenu *)radialMenu imageForIndex:(NSInteger)index {
	UIImage *image = nil;
	
	if (index == 1) {
		image = [UIImage imageNamed:@"fade"];
	} else if (index == 2) {
		image = [UIImage imageNamed:@"gradient"];
	}
	else return nil;
	return image;
}

- (void)radialMenu:(ALRadialMenu *)radialMenu didSelectItemAtIndex:(NSInteger)index {
	[self.radialMenu itemsWillDisapearIntoButton:nil];
	if (index == 1) {
		[self addFadeCommand];
	} else if (index == 2)
	{
		[self addGradientCommand];
	}
}

#pragma mark - ADD OBJECTS
- (void)addFadeCommand {
	NWSetFadeScriptCommandObject *obj = [[NWSetFadeScriptCommandObject alloc] init];
	obj.address = 0xffffffff;
	obj.color = [UIColor greenColor];
	obj.duration = 5;
	obj.parallel = YES;
	
	[self.command.itsScriptObjects addObject:obj];
	[self updateGradientView];
	[self.collectionView reloadData];
	if (self.indexPathOfLastCell) {
		[self.collectionView scrollToItemAtIndexPath:self.indexPathOfLastCell atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
	}
}

- (void)addGradientCommand {
	NWSetGradientScriptCommandObject *obj = [[NWSetGradientScriptCommandObject alloc] init];
	obj.color1 = [UIColor blueColor];
	obj.color2 = [UIColor greenColor];
	obj.offset = 0;
	obj.numberOfLeds = 32;
	
	[self.command.itsScriptObjects addObject: obj];
	[self updateGradientView];
	[self.collectionView reloadData];
	if (self.indexPathOfLastCell) {
		[self.collectionView scrollToItemAtIndexPath:self.indexPathOfLastCell atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
	}
}

#pragma mark - USER ACTIONS

- (void)addCommandButtonPressed:(UIButton *)sender {
	[self.radialMenu buttonsWillAnimateFromButton:sender withFrame:sender.frame inView:self.view];
}

- (void)sendPreview:(UIButton *)sender {
	if (self.controlHandle) {
		[self.controlHandle clearScript];
		[self.controlHandle setColorDirect:[UIColor blackColor]];
		[self.command sendToWCWiflyControl:self.controlHandle];
	}
}

- (void)switchChanged {
	self.command.waitCommand = !self.modeSwitch.on;
	[self updateGradientView];
}

#pragma mark - gesture-recognition action methods
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    CGPoint touchPoint = [touch locationInView:self.collectionView];
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:touchPoint];
    if (indexPath && [gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]])
    {
        return NO;
    }
    return YES;
}

- (void)activateDeletionMode:(UILongPressGestureRecognizer *)gr {
    if (gr.state == UIGestureRecognizerStateBegan)
    {
        NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:[gr locationInView:self.collectionView]];
        if (indexPath && self.command.itsScriptObjects.count > 1)
        {
            self.isDeletionModeActive = YES;
            NWCollectionViewLayout *layout = (NWCollectionViewLayout *)self.collectionView.collectionViewLayout;
            [layout invalidateLayout];
        }
    }
}

- (void)endDeletionMode:(UITapGestureRecognizer *)gr {
    if (self.isDeletionModeActive)
    {
        NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:[gr locationInView:self.collectionView]];
        //if (!indexPath)
        {
            self.isDeletionModeActive = NO;
            NWCollectionViewLayout *layout = (NWCollectionViewLayout *)self.collectionView.collectionViewLayout;
            [layout invalidateLayout];
        }
    }
	else {
		NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:[gr locationInView:self.collectionView]];
		if (indexPath) {
			self.indexOfObjectToAlter = indexPath.row;
			NWScriptCommandObject *obj = [self.command.itsScriptObjects objectAtIndex:self.indexOfObjectToAlter];
			
			if ([obj isKindOfClass:[NWSetFadeScriptCommandObject class]]) {
				[self performSegueWithIdentifier:@"editFade:" sender:self];
			} else if ([obj isKindOfClass:[NWSetGradientScriptCommandObject class]])
			{
				[self performSegueWithIdentifier:@"editGradient:" sender:self];
			}
		}
	}
}

#pragma mark - COLLECTION VIEW STUFF
- (BOOL)isDeletionModeActiveForCollectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout {
	return self.isDeletionModeActive;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	return self.command.itsScriptObjects.count;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
	return 1;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	if (self.isDeletionModeActive) {
		return NO;
	}
	else return YES;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	NWScriptObjectCollectionViewCell *tempCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SCRIPT" forIndexPath:indexPath];
	tempCell.scriptObjectView.endColors = [self.command.itsScriptObjects[indexPath.row] colors];
	
	UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(endDeletionMode:)];
	gesture.numberOfTapsRequired = 1;
	[tempCell addGestureRecognizer:gesture];
	
	[tempCell.deleteButton addTarget:self action:@selector(delete:) forControlEvents:UIControlEventTouchUpInside];
	self.indexPathOfLastCell = indexPath;
	return tempCell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	return CGSizeMake(100, self.collectionView.frame.size.height - 20);
}

#pragma mark - delete for button
- (void)delete:(UIButton *)sender {
	if (self.command.itsScriptObjects.count > 1) {
		NSIndexPath *indexPath = [self.collectionView indexPathForCell:(NWScriptObjectCollectionViewCell *)sender.superview.superview];
		[self.command.itsScriptObjects removeObjectAtIndex:indexPath.row];
		[self.collectionView deleteItemsAtIndexPaths:[NSArray arrayWithObject:indexPath]];
		[self updateGradientView];
	}
	else if (self.isDeletionModeActive) {
		[self endDeletionMode:nil];
	}
}

#pragma mark - SEGUES
- (IBAction)unwindEditScriptObject:(UIStoryboardSegue *)segue {
	if ([segue.sourceViewController respondsToSelector:@selector(command)]) {
		NWScriptCommandObject *cmdObj = (NWScriptCommandObject*)[segue.sourceViewController command];
		[self.command.itsScriptObjects replaceObjectAtIndex:self.indexOfObjectToAlter withObject:cmdObj];
		[self.collectionView reloadData];
	}
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"editFade:"]) {
		if ([segue.destinationViewController isKindOfClass:[NWEditFadeCommandViewController class]]) {
			NWEditFadeCommandViewController *dest = (NWEditFadeCommandViewController*)segue.destinationViewController;
			dest.command = [[self.command.itsScriptObjects objectAtIndex:self.indexOfObjectToAlter] copy];
		}
	} else if ([segue.identifier isEqualToString:@"editGradient:"]) {
		if ([segue.destinationViewController isKindOfClass:[NWEditGradientCommandViewController class]]) {
			NWEditGradientCommandViewController *dest = (NWEditGradientCommandViewController*)segue.destinationViewController;
			dest.command = [[self.command.itsScriptObjects objectAtIndex:self.indexOfObjectToAlter] copy];
		}
	}
}



@end