//
//  OpenCVWrapper.h
//  test
//
//  Created by Huang, Zhi on 3/29/24.
//

//#import <Foundation/Foundation.h>
//
//NS_ASSUME_NONNULL_BEGIN
//
//@interface OpenCVWrapper : NSObject
//
//@end
//
//NS_ASSUME_NONNULL_END
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OpenCVWrapper : NSObject
+ (NSString *)getOpenCVVersion;
+ (UIImage *)grayscaleImg:(UIImage *)image;
+ (UIImage *)resizeImg:(UIImage *)image :(int)width :(int)height :(int)interpolation;
@end

NS_ASSUME_NONNULL_END
