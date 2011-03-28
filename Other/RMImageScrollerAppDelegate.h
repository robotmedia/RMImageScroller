//
//  RMImageScrollerAppDelegate.h
//  RMImageScroller
//
//  Created by Pique on 3/28/11.
//  Copyright 2011 Robot Media. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RMImageScrollerViewController;

@interface RMImageScrollerAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    RMImageScrollerViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet RMImageScrollerViewController *viewController;

@end

