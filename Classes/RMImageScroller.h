//
//  RMImageScroller.h
//  iRobot
//
//  Created by Pique on 3/27/11.
//  Copyright 2011 Robot Media. All rights reserved.
//

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