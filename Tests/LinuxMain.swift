#if os(Linux)
import XCTest
@testable import VaporDMTests

XCTMain([
     testCase(testVaporDM.allTests),
])
#endif
