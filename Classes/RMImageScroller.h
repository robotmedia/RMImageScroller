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

@interface RMScrollerTile : UIView

@property (nonatomic, readonly) UIButton* button;
@property (nonatomic, assign) int index;
@property (nonatomic, readonly) UIImageView* imageView;
@property (nonatomic, readonly) UIImageView *mount; // Image frame
@property (nonatomic, readonly) UILabel* title;
@property (nonatomic, assign) BOOL useImageOriginY;
@property (nonatomic, assign) BOOL useTitleOriginY;

- (void) recycle;

@end

@interface RMImageScroller : UIView<UIScrollViewDelegate> {
	// UI
	UIScrollView* scroller;
    UIColor *selectedImageTitleBackgroundColor;
	UISlider *slider;
	
	// State
    int centeredIndex;
	NSMutableSet* recycledViews;
	BOOL scrollChangeRequestedBySlider;
	BOOL scrollerFrameNeedsLayout;
	BOOL scrollerOffsetNeedsLayout;
	NSMutableSet* visibleViews;
	int selectedIndex;
	
	// Configuration
	__unsafe_unretained id<RMImageScrollerDelegate> delegate;
	BOOL spreadMode;
	BOOL hideSlider;
	int padding;
	int separatorWidth;
	
	BOOL spreadFirstPageAlone;
}

@property (nonatomic, assign) IBOutlet id<RMImageScrollerDelegate> delegate;
@property (nonatomic, assign) BOOL hideSlider;
@property (nonatomic, assign) int imageWidth;
@property (nonatomic, assign) int imageHeight;
@property (nonatomic, assign) int padding;
@property (nonatomic, readonly) UIScrollView* scrollView;
@property (retain, nonatomic) UIColor *selectedImageTitleBackgroundColor;
@property (nonatomic, assign) int separatorWidth;
@property (nonatomic, getter=isSpreadFirstPageAlone) BOOL spreadFirstPageAlone;
@property (nonatomic, assign) BOOL spreadMode;

// Use tile prototype to customize the appearence of tiles
@property (nonatomic, readonly) RMScrollerTile *tilePrototype;
// Supported title prototype properties:
// mount.image
// imageView.frame.origin.y
// imageView.frame.size
// imageView.layer.shadowColor
// imageView.layer.shadowOffset
// imageView.layer.shadowOpacity
// imageView.layer.shadowRadius
// title.frame.origin.y
// title.hidden
// title.backgroundColor
// title.textAlignment
// title.layer.cornerRadius
// title.font
// title.textColor
// title.shadowColor

- (void) reloadImages;
- (void) setSelectedIndex:(int)index;
- (void) setSelectedIndex:(int)index animated:(BOOL)animated;
- (void) setSpreadMode:(BOOL)spreadMode forceLayout:(BOOL)forceLayout;

@end

@protocol RMImageScrollerDelegate<NSObject>
@required
-(UIImage*)		imageScroller:(RMImageScroller*)imageScroller imageAt:(int)index;
- (int)			numberOfImagesInImageScroller:(RMImageScroller*)imageScroller;
@optional
-(void)         imageScroller:(RMImageScroller*)imageScroller centeredImageChanged:(int)index;
-(void)			imageScroller:(RMImageScroller*)imageScroller selected:(int)index;
-(void)			imageScroller:(RMImageScroller*)imageScroller spreadSelectedFrom:(int)startIndex to:(int)endIndex;
-(NSString*)	imageScroller:(RMImageScroller*)imageScroller titleForIndex:(int)index;
@end
