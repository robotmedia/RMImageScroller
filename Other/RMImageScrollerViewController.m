//
//  RMImageScrollerViewController.m
//  RMImageScroller
//
//  Created by Pique on 3/28/11.
//  Copyright 2011 Robot Media. All rights reserved.
//

#import "RMImageScrollerViewController.h"
#import "RMUIUtils.h"

@implementation RMImageScrollerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	selectedImage = [[UIImageView alloc] initWithFrame:self.view.frame];
	selectedImage.contentMode = UIViewContentModeCenter;
	selectedImage.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[self.view addSubview:selectedImage];
	
	scroller = [[RMImageScroller alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 240)];
	scroller.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	scroller.delegate = self;
	scroller.separatorWidth = 10; // Default value: 0
	scroller.imageWidth = 100; // Default value: 100
	scroller.imageHeight = 150; // Default value: as tall as possible within the frame
	scroller.hideTitles = NO; // Default value: NO
	scroller.hideSlider = NO; // Default value: NO
	scroller.spreadMode = YES; // Default value: NO
	[self.view addSubview:scroller];
}


// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return YES;
}

- (void)dealloc {
	[scroller dealloc];
	[selectedImage dealloc];
    [super dealloc];
}

# pragma mark RMImageScrollerDelegate

-(UIImage*) imageScroller:(RMImageScroller*)imageScroller imageAt:(int)index {
	return [UIImage imageNamed:[NSString stringWithFormat:@"yon_kuma_%d.jpg", index]];
}

- (int)	numberOfImagesInImageScroller:(RMImageScroller*)imageScroller {
	return 10;
}

-(NSString*) imageScroller:(RMImageScroller*)imageScroller titleForIndex:(int)index {
	if (index == 0) {
		return @"First";
	} else {
		return nil;
	}
}

-(void) imageScroller:(RMImageScroller*)imageScroller selected:(int)index {
	selectedImage.image = [self imageScroller:imageScroller imageAt:index];
}

-(void)	imageScroller:(RMImageScroller*)imageScroller spreadSelectedFrom:(int)startIndex to:(int)endIndex {
	UIImage* left = [self imageScroller:imageScroller imageAt:startIndex];
	UIImage* right = (startIndex == endIndex) ? nil : [self imageScroller:imageScroller imageAt:endIndex];
	selectedImage.image = [RMUIUtils imageByJoining:left with:right];
}

@end
