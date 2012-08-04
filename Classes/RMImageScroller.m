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

@implementation RMScrollerTile

-(id)initWithFrame:(CGRect)aFrame{
	if (self = [super initWithFrame:aFrame]) {
        
		mount = [[UIImageView alloc] initWithFrame:aFrame];
		[self addSubview:self.mount];
		
        imageView = [[UIImageView alloc] initWithFrame:aFrame];
		self.imageView.backgroundColor = [UIColor clearColor];
		self.imageView.contentMode = UIViewContentModeScaleToFill;
		self.imageView.clipsToBounds = NO;
		self.imageView.layer.shadowColor = [UIColor blackColor].CGColor;
		self.imageView.layer.shadowOffset = CGSizeMake(2, 2);
		self.imageView.layer.shadowOpacity = 0.5;
		self.imageView.layer.shadowRadius = 1.0;
		[self addSubview:self.imageView];
        
		title = [[UILabel alloc] initWithFrame:aFrame];
		self.title.textAlignment = UITextAlignmentCenter;
        self.title.backgroundColor = [UIColor clearColor];
		[self addSubview:self.title];
		
		button = [[UIButton alloc] initWithFrame:aFrame];
		self.button.backgroundColor = [UIColor clearColor];
		self.button.autoresizingMask = imageView.autoresizingMask;
		[self addSubview:self.button];
    }
    return self;
}

- (void) layoutSubviews {
    if (CGRectIsEmpty(self.imageView.frame)) {
        self.imageView.frame = CGRectMake(self.imageView.frame.origin.x, self.imageView.frame.origin.y, self.frame.size.width, self.frame.size.height);
    }
    int imageViewY;
    int imageViewHeight;
    if (self.useImageOriginY) {
        imageViewY = self.imageView.frame.origin.y;
        imageViewHeight = MIN(self.imageView.frame.size.height, self.frame.size.height - imageViewY);
    } else {
        imageViewHeight = MIN(self.imageView.frame.size.height, self.frame.size.height);
        imageViewY = (self.frame.size.height - imageViewHeight) / 2;
    }
    self.imageView.frame = CGRectMake(self.imageView.frame.origin.x, imageViewY, self.imageView.frame.size.width, imageViewHeight);
    
    CGSize titleSize = [title.text sizeWithFont:title.font];
    int titleWidth = MIN(titleSize.width + kImageScrollerTitlePadding * 2, imageView.frame.size.width);
    int titleX = imageView.frame.origin.x + (imageView.frame.size.width - titleWidth) / 2;
    int titleY = self.useTitleOriginY ? self.title.frame.origin.y : self.imageView.frame.origin.y + self.imageView.frame.size.height - titleSize.height - kImageScrollerTitleMargin;
    title.frame = CGRectMake(titleX, titleY, titleWidth, titleSize.height);
    
    if (self.mount.image) {
        self.mount.hidden = NO;
        int mountX = self.imageView.frame.origin.x - (self.mount.image.size.width - self.imageView.frame.size.width) / 2;
        int mountY = self.imageView.frame.origin.y - (self.mount.image.size.height - self.imageView.frame.size.height) / 2;
        self.mount.frame = CGRectMake(mountX, mountY, self.mount.image.size.width, self.mount.image.size.height);
    } else {
        self.mount.hidden = YES;
    }
	button.frame = imageView.frame;
}

- (void) recycle {}

@synthesize button;
@synthesize index;
@synthesize imageView;
@synthesize mount;
@synthesize title;
@synthesize useImageOriginY;
@synthesize useTitleOriginY;

@end

@interface RMImageScroller()

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
- (void) updateSliderAfterScroll;
- (int) selectedIndex;
- (int) centeredIndex;

@end

@implementation RMImageScroller

- (void) initHelper {
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
    
    tilePrototype = [[RMScrollerTile alloc] initWithFrame:CGRectZero];
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

- (int) imageHeight {
    if (CGRectIsEmpty(self.tilePrototype.imageView.frame)) {
        return 1; // Default value to avoid EXC_ARITHMETIC
    } else {
        return self.tilePrototype.imageView.frame.size.height;
    }
}

- (int) imageWidth {
    return self.tilePrototype.imageView.frame.size.width;
}

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

- (void) setImageHeight:(int)imageHeight {
    CGRect currentFrame = self.tilePrototype.imageView.frame;
    CGRect newFrame = CGRectMake(currentFrame.origin.x, currentFrame.origin.y, currentFrame.size.width, imageHeight);
    self.tilePrototype.imageView.frame = newFrame;
}

- (void) setImageWidth:(int)imageWidth {
    CGRect currentFrame = self.tilePrototype.imageView.frame;
    CGRect newFrame = CGRectMake(currentFrame.origin.x, currentFrame.origin.y, imageWidth, currentFrame.size.height);
    self.tilePrototype.imageView.frame = newFrame;
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
            view.title.backgroundColor = self.tilePrototype.title.backgroundColor;
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
	
    {
        CGRect frame = self.tilePrototype.imageView.frame;
        v.imageView.frame = CGRectMake(frame.origin.x, frame.origin.y, self.tileWidth, frame.size.height);
    }
    v.imageView.image = [self imageForIndex:index];
    v.imageView.layer.shadowColor = self.tilePrototype.imageView.layer.shadowColor;
    v.imageView.layer.shadowOffset = self.tilePrototype.imageView.layer.shadowOffset;
    v.imageView.layer.shadowOpacity = self.tilePrototype.imageView.layer.shadowOpacity;
    v.imageView.layer.shadowRadius = self.tilePrototype.imageView.layer.shadowRadius;
    v.useImageOriginY = self.tilePrototype.useImageOriginY;
    
    v.title.frame = self.tilePrototype.title.frame;
    v.title.hidden = self.tilePrototype.title.hidden;
    v.title.backgroundColor = self.tilePrototype.title.backgroundColor;
    v.title.textAlignment = self.tilePrototype.title.textAlignment;
    v.title.layer.cornerRadius = self.tilePrototype.title.layer.cornerRadius;
    v.title.font = self.tilePrototype.title.font;
    v.title.textColor = self.tilePrototype.title.textColor;
    v.useTitleOriginY = self.tilePrototype.useTitleOriginY;
    if (!v.title.hidden) {
		v.title.text = [self titleForIndex:index];
	}
    if (index == [self selectedIndex]) {
        v.title.backgroundColor = selectedImageTitleBackgroundColor;
    }
    
    v.button.tag = index;
	[v.button addTarget:self action:@selector(onScrollerImageButtonTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    
    v.mount.image = self.spreadMode ? nil : self.tilePrototype.mount.image;
    
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
	int index = (int)((UIButton*)sender).tag;
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
	return spreadMode ? self.imageWidth * 2 : self.imageWidth;
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

@synthesize selectedImageTitleBackgroundColor;
@dynamic delegate;
@synthesize hideSlider;
@dynamic imageWidth;
@dynamic imageHeight;
@synthesize padding;
@synthesize scrollView = scroller;
@synthesize separatorWidth;
@synthesize spreadMode;
@synthesize spreadFirstPageAlone;
@synthesize tilePrototype;

@end
