//
//  RMUIUtils.m
//  RMImageScroller
//
//  Created by Pique on 3/28/11.
//  Copyright 2011 Robot Media. All rights reserved.
//

#import "RMUIUtils.h"

@implementation RMUIUtils

+ (UIImage*) imageByJoining:(UIImage*)leftImage with:(UIImage*)rightImage {
	int width = (leftImage ? leftImage.size.width : rightImage.size.width ) + (rightImage ? rightImage.size.width : leftImage.size.width);
	int height = MAX(leftImage ? leftImage.size.height : 0, rightImage ? rightImage.size.height : 0);
	
	UIGraphicsBeginImageContext(CGSizeMake(width, height));
	
    [leftImage drawInRect:CGRectMake(0, (height - leftImage.size.height) / 2, leftImage.size.width, leftImage.size.height)];	
    [rightImage drawInRect:CGRectMake(leftImage ? leftImage.size.width : rightImage.size.width, (height - rightImage.size.height) / 2, rightImage.size.width, rightImage.size.height)];
	
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return result;
}

+ (UIImage *)imageWithColor:(UIColor *)color andSize:(CGSize)size {
	CGRect rect = CGRectMake(0.0f, 0.0f, size.width, size.height);
	UIGraphicsBeginImageContext(rect.size);
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	CGContextSetFillColorWithColor(context, [color CGColor]);
	CGContextFillRect(context, rect);
	
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return image;
}

@end
