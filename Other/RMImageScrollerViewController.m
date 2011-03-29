//
//  RMImageScrollerViewController.m
//  RMImageScroller
//
//  Created by Hermes Pique on 3/27/11.
//	Copyright 2011 Robot Media SL <http://www.robotmedia.net>. All rights reserved.
//
//	This file is part of RMImageScroller.
//
//	RMImageScroller is free software: you can redistribute it and/or modify
//	it under the terms of the GNU Lesser Public License as published by
//	the Free Software Foundation, either version 3 of the License, or
//	(at your option) any later version.
//
//	RMImageScroller is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU Lesser Public License for more details.
//
//	You should have received a copy of the GNU Lesser Public License
//	along with RMImageScroller.  If not, see <http://www.gnu.org/licenses/>.

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
