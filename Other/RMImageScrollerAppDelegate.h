//
//  RMImageScrollerAppDelegate.h
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

@class RMImageScrollerViewController;

@interface RMImageScrollerAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    RMImageScrollerViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet RMImageScrollerViewController *viewController;

@end

