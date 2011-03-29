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
}

@property (nonatomic, readonly) UIButton* button;
@property (nonatomic, assign) int index;
@property (nonatomic, readonly) UIImageView* imageView;
@property (nonatomic, readonly) UILabel* title;

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
	CGSize titleSize = [title.text sizeWithFont:title.font];
	int titleWidth = MIN(MAX(titleSize.width + kImageScrollerTitlePadding * 2, kImageScrollerTitleMinWidth), imageView.frame.size.width);
	int titleX = imageView.frame.origin.x + (imageView.frame.size.width - titleWidth) / 2;
	title.frame = CGRectMake(titleX, 
							   imageView.frame.origin.y + imageView.frame.size.height - kImageScrollerTitleHeight - kImageScrollerTitleMargin, 
							   titleWidth, 
							   kImageScrollerTitleHeight);
	
	button.frame = imageView.frame;
}

- (void)dealloc {
	[button release];
	[imageView release];
	[title release];
    [super dealloc];
}

@synthesize button;
@synthesize index;
@synthesize imageView;
@synthesize title;

@end

@interface RMImageScroller(Private)

- (void) configure:(RMScrollerTile*)view forIndex:(int)index;
- (RMScrollerTile*) dequeueRecycledView;
- (CGRect) frameForIndex:(int)index;
- (int) imageCount;
- (UIImage*) imageForIndex:(int)index;
- (int) indexForX:(int)originX;
- (BOOL) isVisible:(int)index;
- (void) onScrollerImageButtonTouchUpInside:(id)sender;
- (void) scrollToIndex:(int)index;
- (void) tile;
- (int) tileCount;
- (int) tileWidth;
- (NSString*) titleForIndex:(int)index;
- (NSString*) titleForImageIndex:(int)index;
- (void) updateSliderAfterScroll;

@end

@implementation RMImageScroller


-(id)initWithFrame:(CGRect)aFrame{
	if (self = [super initWithFrame:aFrame]) {
		recycledViews = [[NSMutableSet set] retain];
		visibleViews = [[NSMutableSet set] retain];
		
		self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
		slider = [[UISlider alloc] init];
		slider.backgroundColor = [UIColor clearColor];
		slider.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		slider.minimumValue = 1;
		[slider addTarget:self action:@selector(onSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
		[self addSubview:slider];

		scroller = [[UIScrollView alloc] init];
		scrollerFrameNeedsLayout = YES;
		scroller.backgroundColor = [UIColor clearColor];
		scroller.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		scroller.delegate = self;
		[self addSubview:scroller];
		imageWidth = 100; // Default value to avoid EXC_ARITHMETIC
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
}

- (void)dealloc {
	[recycledViews release];
	[scroller release];
	[slider release];
	[visibleViews release];
    [super dealloc];
}

#pragma mark UIScrollViewDelegate

- (void) scrollViewDidScroll:(UIScrollView *)scrollView {
	[self tile];
	if (!scrollChangeRequestedBySlider) {
		[self updateSliderAfterScroll];
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
	[self setNeedsLayout];
}

- (void) setPadding:(int)value {
	padding = value;
	scrollerFrameNeedsLayout = YES;
	[self setNeedsLayout];
}

- (void) setSpreadMode:(BOOL)value {
	spreadMode	= value;
	for (RMScrollerTile* v in visibleViews) {
		[v removeFromSuperview];
	}
	[visibleViews removeAllObjects];
	[recycledViews removeAllObjects];
	slider.maximumValue = [self tileCount];
	[self setNeedsLayout];
}

# pragma mark Private

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
	}
	[v setNeedsLayout];
}

- (RMScrollerTile*) dequeueRecycledView {
    RMScrollerTile *view = [recycledViews anyObject];
    if (view) {
        [[view retain] autorelease];
        [recycledViews removeObject:view];
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
		UIImage* left = [delegate imageScroller:self imageAt:index * 2];
		int rightIndex = (index * 2) + 1;
		UIImage* right;
		if (rightIndex < [self imageCount]) {
			right = [delegate imageScroller:self imageAt:rightIndex];
		} else {
			right = [RMUIUtils imageWithColor:[UIColor whiteColor] andSize:left.size];
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
		index = index * 2;
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
	
}

- (void) onSliderValueChanged:(id)sender {
	int index = slider.value - 1;
	scrollChangeRequestedBySlider = YES;
	[self scrollToIndex:index];
	scrollChangeRequestedBySlider = NO;
}

- (void) scrollToIndex:(int)index {
	int tileWidth = [self tileWidth];
	int x = self.padding + (tileWidth + separatorWidth) * index;
	x -= scroller.frame.size.width / 2 - tileWidth / 2 - separatorWidth / 2;
	scroller.contentOffset = CGPointMake(x, 0);
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
                v = [[[RMScrollerTile alloc] initWithFrame:CGRectMake(0, 0, [self tileWidth], scroller.frame.size.height)] autorelease];
            }
            [self configure:v forIndex:index];
            [scroller addSubview:v];
            [visibleViews addObject:v];
		}
    }    
}

- (int) tileCount {
	int count = [self imageCount];
	return spreadMode ? ceil((double)count / (double)2) : count;
}
- (int) tileWidth {
	return spreadMode ? imageWidth * 2 : imageWidth;
}

- (NSString*) titleForIndex:(int)index {
	if (spreadMode) {
		NSString* left = [self titleForImageIndex:index * 2];
		int rightIndex = (index * 2) + 1;
		NSString* right = nil;
		if (rightIndex < [self imageCount]) {
			right = [self titleForImageIndex:rightIndex];
		}
		return right ? [NSString stringWithFormat:@"%@-%@", left, right] : left;

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

- (void) updateSliderAfterScroll {
	CGRect visibleBounds = scroller.bounds;
	int firstIndex = [self indexForX:CGRectGetMinX(visibleBounds)];
	int lastIndex = [self indexForX:CGRectGetMaxX(visibleBounds)];
	slider.value = round((firstIndex + lastIndex + 2) / 2);
}

#pragma mark Public

- (void) setSelectedIndex:(int)index {
	slider.value = index + 1;
	[self scrollToIndex:index];
}

@dynamic delegate;
@synthesize hideSlider;
@synthesize hideTitles;
@synthesize imageWidth;
@synthesize	imageHeight;
@synthesize padding;
@synthesize separatorWidth;
@synthesize spreadMode;

@end
