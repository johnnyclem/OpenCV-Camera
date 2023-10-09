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
        let humanCascadePath = Bundle.main.path(forResource: "haarcascade_frontalface_default", ofType: "xml")
        XCTAssertNotNil(humanCascadePath, "human cascade path should not be nil")
    }

    func testCatCascadePathIsValid() throws {
        let catCascadePath = Bundle.main.path(forResource: "haarcascade_cat", ofType: "xml")
        XCTAssertNotNil(catCascadePath, "cat cascade path should not be nil")
    }
    
}
