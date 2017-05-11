import Foundation
import PackageDescription

var isSwiftPackagerManagerTest: Bool {
    return ProcessInfo.processInfo.environment["SWIFTPM_TEST_VaporDM"] == "YES"
}

let package = Package(
    name: "VaporDM",
    dependencies: {
        var deps: [Package.Dependency] = [
            .Package(url: "https://github.com/vapor/vapor.git", majorVersion: 1)
            ]
        if isSwiftPackagerManagerTest {
            deps += [
                .Package(url: "https://github.com/vapor/postgresql-provider.git", majorVersion: 1, minor: 1)
            ]
        }
        return deps
    }(),
    exclude: [
        "Config",
        "Database",
        "Localization",
        "Public",
        "Resources",
    ]
)

