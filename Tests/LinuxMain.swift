#if os(Linux)
import XCTest
@testable import VaporDMTests

XCTMain([
     testCase(testVaporDM.allTests),
     testCase(testDirectMessage.allTests),
     testCase(testExtensions.allTests),
     testCase(testVaporDMController.allTests),
])
#endif
