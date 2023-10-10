//
//  OpenCVDetector.h
//  OpenCV_Cam
//
//  Created by Jonathan Clem on 10/9/23.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface OpenCVDetector : NSObject

+ (UIImage *)detectFeaturesIn:(UIImage *)image forSpecies:(NSString *)species;
+ (BOOL) checkForBurryImage:(UIImage *)image forCameraPosition:(AVCaptureDevicePosition)position;

@end
