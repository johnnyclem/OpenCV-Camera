//
//  OpenCVDetector.m
//  OpenCV_Cam
//
//  Created by Jonathan Clem on 10/9/23.
//


#import "OpenCVDetector.h"
#import <opencv2/opencv2.h>
#import <opencv2/objdetect/objdetect.hpp>
#import <opencv2/objdetect.hpp>
#import <CoreGraphics/CoreGraphics.h>

@implementation OpenCVDetector

cv::CascadeClassifier faceCascade;
cv::CascadeClassifier catCascade;
bool cascade_loaded = false;

+ (UIImage *)detectFeaturesIn:(UIImage *)image forSpecies:(NSString *)species {

    // vector to store detected features
    std::vector<cv::Rect> detectedFeatures;

    // resize the image down to SD resolution
    UIImage *resizedImage = [OpenCVDetector resizeImage:image toSize:CGSizeMake(360, 640)];

    // convert the supplied image into OpenCV mat format
    cv::Mat frame = [OpenCVDetector cvMatFromUIImage:resizedImage];
    // Transform source image to gray
    cv::Mat frame_gray;
    cvtColor(frame, frame_gray, COLOR_BGR2GRAY);
    
    // load face detection cascade
    NSString *face_cascade_path = [[NSBundle mainBundle] pathForResource:@"haarcascade_frontalface_default" ofType:@"xml"];
    NSString *cat_cascade_path = [[NSBundle mainBundle] pathForResource:@"haarcascade_cat" ofType:@"xml"];
    if (!cascade_loaded) {
        if (!faceCascade.load( std::string([face_cascade_path UTF8String]))) {
            NSLog(@"Error loading face cascade");
            return image;
        }
        if (!catCascade.load( std::string([cat_cascade_path UTF8String]))) {
            NSLog(@"Error loading cat cascade");
            return image;
        }
        cascade_loaded = true;
    }
    // detect features
    if ([species isEqualToString:@"cat"]) {
        catCascade.detectMultiScale(frame_gray, detectedFeatures, 1.3, 5);
    } else {
        faceCascade.detectMultiScale(frame_gray, detectedFeatures, 1.3, 5);
    }
    for ( size_t i = 0; i < detectedFeatures.size(); i++ ) {
        // get the center of the detected face
        cv::Point center( detectedFeatures[i].x + detectedFeatures[i].width*0.5, detectedFeatures[i].y + detectedFeatures[i].height*0.5 );
        // draw an ellipse around the face
        ellipse( frame, center, cv::Size( detectedFeatures[i].width*0.5, detectedFeatures[i].height*0.5), 0, 0, 360, cv::Scalar( 150, 50, 255 ), 4, 8, 0 );
    }
    
    // convert the cv mat back into a UIImage
    NSData *data = [NSData dataWithBytes:frame.data length:frame.elemSize() * frame.total()];
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    CGBitmapInfo bitmapInfo = kCGImageAlphaNoneSkipLast | kCGBitmapByteOrderDefault;
    size_t bitsPerComponent = 8;
    size_t bytesPerRow = frame.step[0];
    CGColorSpaceRef colorSpace = (frame.elemSize() == 1 ? CGColorSpaceCreateDeviceGray() : CGColorSpaceCreateDeviceRGB());
    
    CGImageRef imageRef = CGImageCreate(frame.cols, frame.rows, bitsPerComponent, bitsPerComponent * frame.elemSize(), bytesPerRow, colorSpace, bitmapInfo, provider, NULL, false, kCGRenderingIntentDefault);
    UIImage *result = [UIImage imageWithCGImage:imageRef];
    
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);

    return result;
}

+ (cv::Mat)cvMatFromUIImage:(UIImage *)image {
    // Get colorspace from current image
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    // create CGContext
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,
                                                    cols,
                                                    rows,
                                                    8,
                                                    cvMat.step[0],
                                                    colorSpace,
                                                    kCGImageAlphaNoneSkipLast | kCGBitmapByteOrderDefault);
    // Draw image
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    return cvMat;
}

+ (BOOL) checkForBurryImage:(UIImage *)image forCameraPosition:(AVCaptureDevicePosition)position {
    // resize the image because this operation is computationally expensive
    UIImage *resizedImage = [OpenCVDetector resizeImage:image toSize:CGSizeMake(360, 640)];
    // convert UIImage to cv::Mat format
    cv::Mat matImage = [OpenCVDetector cvMatFromUIImage:resizedImage];
    // blur threshold of 75 gives good results for rear camera
    int blurThreshhold;
    if (position == AVCaptureDevicePositionBack) {
        blurThreshhold = 75;
    } else {
        blurThreshhold = 30;
    }
    
    cv::Mat finalImage;
    cv::Mat matImageGrey;
    
    // Convert the image to grayscale for analysis
    cv::cvtColor(matImage, matImageGrey, COLOR_BGRA2GRAY);
    matImage.release();

    // Median size for blur filter
    const int MEDIAN_BLUR_FILTER_SIZE = 15;

    // Apply the median blur to the grayscale image
    cv::Mat newEX;
    cv::medianBlur(matImageGrey, newEX, MEDIAN_BLUR_FILTER_SIZE);
    matImageGrey.release();

    // Copmute the Laplacian of the blurred image to detect edges
    cv::Mat laplacianImage;
    cv::Laplacian(newEX, laplacianImage, CV_8U);
    newEX.release();
    
    // Convert the Laplacian image to 8-bit format
    cv::Mat laplacianImage8bit;
    laplacianImage.convertTo(laplacianImage8bit, CV_8UC1);
    laplacianImage.release();
    
    // Convert the 8-bit Laplacian image back to BGRA format
    cv::cvtColor(laplacianImage8bit,finalImage, COLOR_GRAY2BGRA);
    laplacianImage8bit.release();
    
    // Get the rows/columns of final image
    int rows = finalImage.rows;
    int cols= finalImage.cols;
    
    // Iterate over pixel data to find the maximum Laplacian value
    char *pixels = reinterpret_cast<char *>( finalImage.data);
    int maxLap = -16777216;
    for (int i = 0; i < (rows*cols); i++) {
        if (pixels[i] > maxLap) {
            maxLap = pixels[i];
        }
    }
    
    // Clean up
    pixels=NULL;
    finalImage.release();
    
    // Determine if image is blurry
    BOOL isBlur = (maxLap < blurThreshhold)?  YES :  NO;
    return isBlur;
}

+ (UIImage *)resizeImage:(UIImage *)image toSize:(CGSize)newSize {
    CGFloat scale = MAX(1.0f, image.scale);
    CGRect newRect = CGRectIntegral(CGRectMake(0, 0, newSize.width*scale, newSize.height*scale));
    CGImageRef imageRef = image.CGImage;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef bitmap = CGBitmapContextCreate(
                                                NULL,
                                                newRect.size.width,
                                                newRect.size.height,
                                                8,
                                                (newRect.size.width * 4),
                                                colorSpace,
                                                kCGImageAlphaPremultipliedLast
                                                );
    CGColorSpaceRelease(colorSpace);
    
    // Set the quality level to use when rescaling
    CGContextSetInterpolationQuality(bitmap, kCGInterpolationDefault);
    
    // Draw into the context; this scales the image
    CGContextDrawImage(bitmap, newRect, imageRef);
    
    // Get the resized image from the context and a UIImage
    CGImageRef newImageRef = CGBitmapContextCreateImage(bitmap);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef scale:scale orientation:UIImageOrientationUp];
    
    // Clean up
    CGContextRelease(bitmap);
    CGImageRelease(newImageRef);
    
    return newImage;
}
@end
