//
//  OpenCV_CamTests.swift
//  OpenCV_CamTests
//
//  Created by Jonathan Clem on 10/9/23.
//

import XCTest
@testable import OpenCV_Cam

final class OpenCV_CamTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testHumanCascadePathIsValid() throws {
        let humanCascadePath = Bundle.main.path(forResource: faceCascadePath, ofType: "xml")
        XCTAssertNotNil(humanCascadePath, "human cascade path should not be nil")
    }

    func testCatCascadePathIsValid() throws {
        let catCascadePath = Bundle.main.path(forResource: catCascadePath, ofType: "xml")
        XCTAssertNotNil(catCascadePath, "cat cascade path should not be nil")
    }
    
    func testKnownBlurryImage() throws {
        let blurryImage = UIImage(named: "blurry_image.jpg", in: Bundle(for: type(of: self)), compatibleWith: nil)
        XCTAssertNotNil(blurryImage, "failed to load blurry image")
        let isBlurry = OpenCVDetector.check(forBurryImage: blurryImage!, forCameraPosition: .back)
        XCTAssertTrue(isBlurry, "known blurry image should be recognized as blurry")
    }
    
    func testKnownClearImage() throws {
        let clearImage = UIImage(named: "clear_image.jpg", in: Bundle(for: type(of: self)), compatibleWith: nil)
        XCTAssertNotNil(clearImage, "failed to load clear image")
        let isBlurry = OpenCVDetector.check(forBurryImage: clearImage!, forCameraPosition: .back)
        XCTAssertFalse(isBlurry, "known clear image should be recognized as not blurry")
    }
    
    func testImageResize() throws {
        let clearImage = UIImage(named: "clear_image.jpg", in: Bundle(for: type(of: self)), compatibleWith: nil)
        XCTAssertNotNil(clearImage, "failed to load clear image")

        let imageHeight = clearImage!.size.height
        let imageWidth = clearImage!.size.width
        XCTAssertGreaterThan(imageHeight, 2000, "test image should be 1170x2083")
        XCTAssertGreaterThan(imageWidth, 1000, "test image should be 1170x2083")

        let resizedImage = OpenCVDetector.resize(clearImage, to: CGSizeMake(320, 640))
        XCTAssertNotNil(resizedImage, "image resize function should return an image")
        XCTAssertEqual(resizedImage!.size.width, 320, "resize function should adjust width to 320 pixels")
        XCTAssertEqual(resizedImage!.size.height, 640, "resize function should adjust height to 640 pixels")
    }
}
