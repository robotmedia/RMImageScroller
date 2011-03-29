//
//  RMUIUtils.m
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
