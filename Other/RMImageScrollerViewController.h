//
//  RMImageScrollerViewController.h
//  RMImageScroller
//
//  Created by Pique on 3/28/11.
//  Copyright 2011 Robot Media. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RMImageScroller.h"

@interface RMImageScrollerViewController : UIViewController<RMImageScrollerDelegate> {
	RMImageScroller* scroller;
	UIImageView* selectedImage;
}

@end

