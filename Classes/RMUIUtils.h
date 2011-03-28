//
//  RMUIUtils.h
//  RMImageScroller
//
//  Created by Pique on 3/28/11.
//  Copyright 2011 Robot Media. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface RMUIUtils : UIView {

}

+ (UIImage*) imageByJoining:(UIImage*)leftImage with:(UIImage*)rightImage;
+ (UIImage *)imageWithColor:(UIColor *)color andSize:(CGSize)size;

@end
