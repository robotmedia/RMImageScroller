//
//  RMImageScroller.m
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

#import "RMImageScroller.h"
#import "RMUIUtils.h"
#import <QuartzCore/QuartzCore.h>

#define kImageScrollerSliderHeight 23
#define kImageScrollerTitlePadding 5
#define kImageScrollerTitleMargin 5
#define kImageScrollerTitleHeight 20
#define kImageScrollerTitleMinWidth 30

@interface RMScrollerTile : UIView {
	UIButton* button;
	UIImageView* imageView;
	int index;
	UILabel* title;
    UIView* titleView;
}

@property (nonatomic, readonly) UIButton* button;
@property (nonatomic, assign) int index;
@property (nonatomic, readonly) UIImageView* imageView;
@property (nonatomic, readonly) UILabel* title;
@property (nonatomic, strong) UIView* titleView;

- (void) recycle;

@end

@implementation RMScrollerTile 

-(id)initWithFrame:(CGRect)aFrame{
	if (self = [super initWithFrame:aFrame]) {
        
		imageView = [[UIImageView alloc] initWithFrame:aFrame];
		imageView.backgroundColor = [UIColor clearColor];
		imageView.contentMode = UIViewContentModeScaleToFill;
		imageView.clipsToBounds = NO;
		imageView.layer.shadowColor = [UIColor blackColor].CGColor;
		imageView.layer.shadowOffset = CGSizeMake(2, 2);
		imageView.layer.shadowOpacity = 0.5;
		imageView.layer.shadowRadius = 1.0;
		[self addSubview:imageView];
		
		title = [[UILabel alloc] init];
		title.backgroundColor = [UIColor lightGrayColor];
		title.textAlignment = UITextAlignmentCenter;
		title.layer.cornerRadius = 8;
		title.font = [UIFont systemFontOfSize:14];
		title.textColor = [UIColor whiteColor];
		[self addSubview:title];
		
		button = [[UIButton alloc] init];
		button.backgroundColor = [UIColor clearColor];
		button.autoresizingMask = imageView.autoresizingMask;
		[self addSubview:button];
    }
    return self;
}

- (void) layoutSubviews {	
    if (!self.titleView) {
        CGSize titleSize = [title.text sizeWithFont:title.font];
        int titleWidth = MIN(MAX(titleSize.width + kImageScrollerTitlePadding * 2, kImageScrollerTitleMinWidth), imageView.frame.size.width);
        int titleX = imageView.frame.origin.x + (imageView.frame.size.width - titleWidth) / 2;
        title.frame = CGRectMake(titleX, 
							 imageView.frame.origin.y + imageView.frame.size.height - kImageScrollerTitleHeight - kImageScrollerTitleMargin, 
							 titleWidth, 
							 kImageScrollerTitleHeight);
    }
	
	button.frame = imageView.frame;
}

- (void) recycle {
    [self.titleView removeFromSuperview];
    self.titleView = nil;
    self.title.hidden = NO;
}

- (void) setTitleView:(UIView *)value {
    [self.titleView removeFromSuperview];
    titleView = value;
    if (self.titleView) {
        [self addSubview:titleView];
        self.title.hidden = YES;
    }
}


@synthesize button;
@synthesize index;
@synthesize imageView;
@synthesize title;
@synthesize titleView;

@end

@interface RMImageScroller(Private)

- (int) calculateCenteredIndex;
- (int) centeredIndex;
- (void) centeredImageChanged;
- (void) configure:(RMScrollerTile*)view forIndex:(int)index;
- (RMScrollerTile*) dequeueRecycledView;
- (CGRect) frameForIndex:(int)index;
- (int) imageCount;
- (void) initHelper;
- (UIImage*) imageForIndex:(int)index;
- (int) indexForX:(int)originX;
- (void) updateSelectedTile;
- (BOOL) isVisible:(int)index;
- (void) onScrollerImageButtonTouchUpInside:(id)sender;
- (void) scrollToIndex:(int)index;
- (void) scrollToIndex:(int)index animated:(BOOL)animated;
- (void) tile;
- (int) tileCount;
- (int) tileWidth;
- (NSString*) titleForIndex:(int)index;
- (NSString*) titleForImageIndex:(int)index;
- (UIView*) titleViewForImageIndex:(int)index;
- (void) updateSliderAfterScroll;
- (int) selectedIndex;
- (int) centeredIndex;

@end

@implementation RMImageScroller

- (void) initHelper {
    imageTitleBackgroundColor = [UIColor lightGrayColor];
    selectedImageTitleBackgroundColor = [UIColor darkGrayColor];
    
    recycledViews = [NSMutableSet set];
    visibleViews = [NSMutableSet set];
    
    self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    slider = [[UISlider alloc] init];
    slider.backgroundColor = [UIColor clearColor];
    slider.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    slider.minimumValue = 1;
    [slider addTarget:self action:@selector(onSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:slider];
    
    scroller = [[UIScrollView alloc] init];
    scrollerFrameNeedsLayout = YES;
    scrollerOffsetNeedsLayout = YES;
    scroller.backgroundColor = [UIColor clearColor];
    scroller.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    scroller.delegate = self;
    [self addSubview:scroller];
    imageWidth = 100; // Default value to avoid EXC_ARITHMETIC
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super initWithCoder:aDecoder]) {
        [self initHelper];
    }
    return self;
}

-(id)initWithFrame:(CGRect)aFrame{
	if (self = [super initWithFrame:aFrame]) {
        [self initHelper];
    }
    return self;
}

- (void) layoutSubviews {
	slider.hidden = hideSlider;
	slider.frame = CGRectMake(self.padding, 
							  self.frame.size.height - kImageScrollerSliderHeight - self.padding, 
							  self.frame.size.width - self.padding * 2,
							  kImageScrollerSliderHeight);
	if (scrollerFrameNeedsLayout) {
		int scrollerHeight = (hideSlider ? self.frame.size.height : slider.frame.origin.y) - self.padding * 2;
		scroller.frame = CGRectMake(0, self.padding, self.frame.size.width, scrollerHeight);
		scrollerFrameNeedsLayout = NO; // Avoid setting the scroller frame on scroll changes
	}
	int count = [self tileCount];
	int contentWidth = count * [self tileWidth];
	contentWidth += count * separatorWidth;
	contentWidth += self.padding * 2;
	scroller.contentSize = CGSizeMake(contentWidth, scroller.frame.size.height);
	[self tile];
	if (scrollerOffsetNeedsLayout) {
		[self setSelectedIndex:selectedIndex];
		scrollerOffsetNeedsLayout = NO;
	}
}


#pragma mark UIScrollViewDelegate

- (void) scrollViewDidScroll:(UIScrollView *)scrollView {
	[self tile];
	if (!scrollChangeRequestedBySlider) {
		[self updateSliderAfterScroll];
        slider.value = [self calculateCenteredIndex] + 1;
	}
}

#pragma mark Properties

- (void) setDelegate:(id <RMImageScrollerDelegate>)aDelegate {
	delegate = aDelegate;
	slider.maximumValue = [self tileCount];
}

- (void) setHideSlider:(BOOL)value {
	hideSlider = value;
	scrollerFrameNeedsLayout = YES;
	scrollerOffsetNeedsLayout = YES;
	[self setNeedsLayout];
}

- (void) setPadding:(int)value {
	padding = value;
	scrollerFrameNeedsLayout = YES;
	scrollerOffsetNeedsLayout = YES;
	[self setNeedsLayout];
}

- (void) setSpreadMode:(BOOL)value {
	[self setSpreadMode:value forceLayout:YES];
}

- (void) setSpreadMode:(BOOL)value forceLayout:(BOOL)forceLayout {
	spreadMode = value;
	if (forceLayout) {
		scrollerOffsetNeedsLayout = YES;
		[self reloadImages];
	}
}

# pragma mark Private

- (void) updateSelectedTile {
    for (RMScrollerTile *view in visibleViews) {
        if (view.index == [self selectedIndex]) {
            view.title.backgroundColor = selectedImageTitleBackgroundColor;
        } else {
            view.title.backgroundColor = imageTitleBackgroundColor;
        }
    }
}

- (int) calculateCenteredIndex {
    int centerX = scroller.contentOffset.x + (scroller.frame.size.width / 2);
	return [self indexForX:centerX];
}

- (void) centeredImageChanged {
    if ([delegate respondsToSelector:@selector(imageScroller:centeredImageChanged:)]) {
        [delegate imageScroller:self centeredImageChanged:[self centeredIndex]];
    }
}

- (void) configure:(RMScrollerTile*)v forIndex:(int)index {
    v.index = index;
    v.frame = [self frameForIndex:index];
	int imageViewHeight = imageHeight ? MIN(imageHeight, v.frame.size.height) : v.frame.size.height;
	int imageViewY = (v.frame.size.height - imageViewHeight) / 2;
	v.imageView.frame = CGRectMake(0, imageViewY, v.imageView.frame.size.width, imageViewHeight);
	v.imageView.image = [self imageForIndex:index];
	v.button.tag = index;
	[v.button addTarget:self action:@selector(onScrollerImageButtonTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
	if (hideTitles) {
		v.title.hidden = YES;
	} else {
		v.title.hidden = NO;
		v.title.text = [self titleForIndex:index];
        if (!spreadMode) {
            v.titleView = [self titleViewForImageIndex:index];
        }
	}
    if (index == [self selectedIndex]) {
        v.title.backgroundColor = selectedImageTitleBackgroundColor;
    } else {
        v.title.backgroundColor = imageTitleBackgroundColor;
    }
	[v setNeedsLayout];
}

- (RMScrollerTile*) dequeueRecycledView {
    RMScrollerTile *view = [recycledViews anyObject];
    if (view) {
        [recycledViews removeObject:view];
        [view recycle];
    }
    return view;
}

- (CGRect) frameForIndex:(int)index {
	int tileWidth = [self tileWidth];
    CGRect tileFrame = CGRectMake(0, 0, tileWidth, scroller.frame.size.height - 2*self.padding);
	tileFrame.origin.x = self.padding + (tileWidth + separatorWidth) * index;
    return tileFrame;
}

- (int) imageCount {
	return [delegate numberOfImagesInImageScroller:self];
}

- (UIImage*) imageForIndex:(int)index {
	if (spreadMode) {
		int leftIndex, rightIndex;
		if ([self isSpreadFirstPageAlone]) {
			leftIndex = (index * 2) - 1;
			rightIndex = index * 2;
		} else {
			leftIndex = index * 2;
			rightIndex = (index * 2) + 1;
		}
		UIImage* left = nil;
		if (leftIndex >= 0) {
			left = [delegate imageScroller:self imageAt:leftIndex];
		}
		
		UIImage* right = nil;
		if (rightIndex < [self imageCount]) {
			right = [delegate imageScroller:self imageAt:rightIndex];
		}
		
		if (!left) {
			if (right) {
				left = [RMUIUtils imageWithColor:[UIColor whiteColor] andSize:right.size];
			} else {
				left = [RMUIUtils imageWithColor:[UIColor whiteColor] andSize:CGSizeMake(self.imageWidth, self.imageHeight)];
			}
		}
		if (!right) {
			if (left) {
				right = [RMUIUtils imageWithColor:[UIColor whiteColor] andSize:left.size];
			} else {
				right = [RMUIUtils imageWithColor:[UIColor whiteColor] andSize:CGSizeMake(self.imageWidth, self.imageHeight)];
			}
		}
		return [RMUIUtils imageByJoining:left with:right];
	} else {
		return [delegate imageScroller:self imageAt:index];
	}
}

- (int) indexForX:(int)originX {
	int count = [self tileCount];
	int tileWidth = [self tileWidth];
	int firstTileWidth = self.padding + tileWidth;
	int otherTileWidth = tileWidth + separatorWidth;
	
	int index;
	if (originX < firstTileWidth) {
		index = 0;
	} else {
		originX -= firstTileWidth;
		index = floorf(originX / otherTileWidth) + 1;
	}
	index = MIN(MAX(index, 0), count - 1);
	return index;
}

- (BOOL) isVisible:(int)index {
    BOOL found = NO;
    for (RMScrollerTile *view in visibleViews) {
        if (view.index == index) {
            found = YES;
            break;
        }
    }
    return found;
}

- (void) onScrollerImageButtonTouchUpInside:(id)sender {
	int index = ((UIButton*)sender).tag;
	if (spreadMode) {
		if ([self isSpreadFirstPageAlone]) {
			index = MAX(0, index * 2 - 1);
		} else {
			index = index * 2;
		}
		if ([delegate respondsToSelector:@selector(imageScroller:spreadSelectedFrom:to:)]) {
			int lastIndex = index + 1;
			if (lastIndex >= [self imageCount]) {
				lastIndex = index;
			}
			[delegate imageScroller:self spreadSelectedFrom:index to:lastIndex];
		}
	} else if ([delegate respondsToSelector:@selector(imageScroller:selected:)]) {
		[delegate imageScroller:self selected:index];
	}
	selectedIndex = index;
	[self updateSelectedTile];
}

- (void) onSliderValueChanged:(id)sender {
	int index = slider.value - 1;
	scrollChangeRequestedBySlider = YES;
	[self scrollToIndex:index];
	scrollChangeRequestedBySlider = NO;
}

- (void) scrollToIndex:(int)index {
	[self scrollToIndex:index animated:NO];
}

- (void) scrollToIndex:(int)index animated:(BOOL)animated {
	int tileWidth = [self tileWidth];
	int x = self.padding + (tileWidth + separatorWidth) * index;
	x -= scroller.frame.size.width / 2 - tileWidth / 2 - separatorWidth / 2;
	[scroller setContentOffset:CGPointMake(x, 0) animated:animated];
}

- (void) tile {
    CGRect visibleBounds = scroller.bounds;
	int firstIndex = [self indexForX:CGRectGetMinX(visibleBounds)];
	int lastIndex = [self indexForX:CGRectGetMaxX(visibleBounds)];
	
    // Recycle no-longer-visible images 
    for (RMScrollerTile *v in visibleViews) {
        if (v.index < firstIndex || v.index > lastIndex) {
            [recycledViews addObject:v];
            [v removeFromSuperview];
        }
    }
    [visibleViews minusSet:recycledViews];
    
    // Add missing images
    for (int index = firstIndex; index <= lastIndex; index++) {
        if (![self isVisible:index]) {
            RMScrollerTile *v = [self dequeueRecycledView];
            if (v == nil) {
                v = [[RMScrollerTile alloc] initWithFrame:CGRectMake(0, 0, [self tileWidth], scroller.frame.size.height)];
            }
            [self configure:v forIndex:index];
            [scroller addSubview:v];
            [visibleViews addObject:v];
		}
    }
    
    // Update centered index
    int newCenteredIndex = [self calculateCenteredIndex];
    if (centeredIndex != newCenteredIndex) {
        centeredIndex = newCenteredIndex;
        [self centeredImageChanged];
    }
	
}

- (int) tileCount {
	int count = [self imageCount];
	if (spreadMode) {
		if ([self isSpreadFirstPageAlone]) {
			return ceil(((double)count+1) / (double)2);
		} else {
			return ceil((double)count / (double)2);
		}
	} else {
		return count;
	}
	
	return spreadMode ? ceil((double)count / (double)2) : count;
}
- (int) tileWidth {
	return spreadMode ? imageWidth * 2 : imageWidth;
}

- (NSString*) titleForIndex:(int)index {
	if (spreadMode) {
		int leftIndex;
		if ([self isSpreadFirstPageAlone]) {
			leftIndex = (index * 2) - 1;
		} else {
			leftIndex = index * 2;
		}
		NSString* left = nil;
		if (leftIndex >= 0) {
			left = [self titleForImageIndex:leftIndex];
		}
		
		int rightIndex;
		if ([self isSpreadFirstPageAlone]) {
			rightIndex = index * 2;
		} else {
			rightIndex = (index * 2) + 1;
		}
		
		NSString* right = nil;
		if (rightIndex < [self imageCount]) {
			right = [self titleForImageIndex:rightIndex];
		}
		
		if (left && right) {
			return [NSString stringWithFormat:@"%@-%@", left, right];
		} else if (right) {
			return right;
		} else {
			return left;
		}
		
	} else {
		return [self titleForImageIndex:index];
	}
	
}

- (NSString*) titleForImageIndex:(int)index {
	if ([delegate respondsToSelector:@selector(imageScroller:titleForIndex:)]) {
		NSString* title = [delegate imageScroller:self titleForIndex:index];
		if (title) {
			return title;
		}
	}
	return [NSString stringWithFormat:@"%d", index + 1];
}

- (UIView*) titleViewForImageIndex:(int)index {
    if ([delegate respondsToSelector:@selector(imageScroller:titleViewForIndex:)]) {
		return [delegate imageScroller:self titleViewForIndex:index];
	}
    return nil;
}

- (void) updateSliderAfterScroll {
	CGRect visibleBounds = scroller.bounds;
	int firstIndex = [self indexForX:CGRectGetMinX(visibleBounds)];
	int lastIndex = [self indexForX:CGRectGetMaxX(visibleBounds)];
	slider.value = round((firstIndex + lastIndex + 2) / 2);
}

- (int) selectedIndex {
	if (spreadMode) {
		if ([self isSpreadFirstPageAlone]) {
			return ceil(((double)selectedIndex / (double)2));
		} else {
			return ceil(((double)selectedIndex-1) / (double)2);
		}
	} else {
		return selectedIndex;
	}
}

- (int) centeredIndex {
	if (spreadMode) {
		if ([self isSpreadFirstPageAlone]) {
			return ceil(((double)centeredIndex / (double)2));
		} else {
			return ceil(((double)centeredIndex-1) / (double)2);
		}
	} else {
		return centeredIndex;
	}
}

#pragma mark Public

- (void) reloadImages {
	for (RMScrollerTile* v in visibleViews) {
		[v removeFromSuperview];
	}
	[visibleViews removeAllObjects];
	[recycledViews removeAllObjects];
	slider.maximumValue = [self tileCount];
	//scrollerOffsetNeedsLayout = YES;
	[self setNeedsLayout];
}

- (void) setSelectedIndex:(int)index {
	[self setSelectedIndex:index animated:NO];
}

- (void) setSelectedIndex:(int)index animated:(BOOL)animated {
	if (index < 0) {
		index = 0;
	}
    selectedIndex = index;
	slider.value = [self selectedIndex] + 1;
    [self updateSelectedTile];
	[self scrollToIndex:[self selectedIndex] animated:animated];
}

@synthesize imageTitleBackgroundColor, selectedImageTitleBackgroundColor;
@dynamic delegate;
@synthesize hideSlider;
@synthesize hideTitles;
@synthesize imageWidth;
@synthesize	imageHeight;
@synthesize padding;
@synthesize separatorWidth;
@synthesize spreadMode;
@synthesize spreadFirstPageAlone;

@end
