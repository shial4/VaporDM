#if os(Linux)
import XCTest
@testable import VaporDMTests

XCTMain([
     testCase(testVaporDM.allTests),
     testCase(testDirectMessage.allTests),
     testCase(testExtensions.allTests),
     testCase(testVaporDMController.allTests),
     testCase(testLogs.allTests),
     testCase(testEvents.allTests),
])
#endif
