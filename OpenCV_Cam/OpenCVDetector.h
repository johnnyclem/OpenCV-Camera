//
//  OpenCVDetector.h
//  OpenCV_Cam
//
//  Created by Jonathan Clem on 10/9/23.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NSString *const faceCascadePath = @"haarcascade_frontalface_default";
NSString *const catCascadePath = @"haarcascade_cat";

@interface OpenCVDetector : NSObject

+ (UIImage *)detectFeaturesIn:(UIImage *)image forSpecies:(NSString *)species;
+ (BOOL) checkForBurryImage:(UIImage *)image forCameraPosition:(AVCaptureDevicePosition)position;
+ (UIImage *)resizeImage:(UIImage *)image toSize:(CGSize)newSize;

@end
