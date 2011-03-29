//
//  RMImageScroller.h
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

#import <UIKit/UIKit.h>

@protocol RMImageScrollerDelegate;

@interface RMImageScroller : UIView<UIScrollViewDelegate> {
	// UI
	UIScrollView* scroller;
	UISlider *slider;

	// State
	BOOL scrollChangeRequestedBySlider;
	NSMutableSet* recycledViews;
	NSMutableSet* visibleViews;
	
	// Configuration
	id<RMImageScrollerDelegate> delegate;
	BOOL spreadMode;
	BOOL hideSlider;
	BOOL hideTitles;
	int padding;
	int imageWidth;
	int imageHeight;
	int separatorWidth;
}

@property (nonatomic, assign) id<RMImageScrollerDelegate> delegate;
@property (nonatomic, assign) BOOL spreadMode;
@property (nonatomic, assign) BOOL hideSlider;
@property (nonatomic, assign) BOOL hideTitles;
@property (nonatomic, assign) int imageWidth;
@property (nonatomic, assign) int imageHeight;
@property (nonatomic, assign) int padding;
@property (nonatomic, assign) int separatorWidth;

- (void) setSelectedIndex:(int)index;

@end

@protocol RMImageScrollerDelegate<NSObject>
@required
-(UIImage*)		imageScroller:(RMImageScroller*)imageScroller imageAt:(int)index;
- (int)			numberOfImagesInImageScroller:(RMImageScroller*)imageScroller;
@optional
-(void)			imageScroller:(RMImageScroller*)imageScroller selected:(int)index;
-(void)			imageScroller:(RMImageScroller*)imageScroller spreadSelectedFrom:(int)startIndex to:(int)endIndex;
-(NSString*)	imageScroller:(RMImageScroller*)imageScroller titleForIndex:(int)index;
@end