// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "SwiftAstronomy",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v12),
        .watchOS(.v7)
    ],
    products: [
        // The C++ astronomical algorithms library by J.P. Naughter
        .library(name: "AAplus", targets: ["AAplus"]),
        // The Swift wrapper API
        .library(name: "SwiftAstronomy", targets: ["SwiftAstronomy"])
    ],
    targets: [
        // MARK: - C++ Core
        .target(
            name: "AAplus",
            path: "Sources/AA+",
            exclude: [
                "AAVSOP2013.h",
                "AAVSOP2013.cpp"
            ],
            publicHeadersPath: ".",
            cxxSettings: [
                .headerSearchPath(".")
            ]
        ),

        // MARK: - Swift API
        .target(
            name: "SwiftAstronomy",
            dependencies: ["AAplus"],
            path: "Sources/SwiftAstronomy",
            exclude: ["SwiftAstronomy-Info.plist", "SwiftAstronomy.playground"],
            resources: [
                .process("SwiftAstronomy.docc")
            ],
            swiftSettings: [
                .interoperabilityMode(.Cxx)
            ]
        ),
        .testTarget(
            name: "SwiftAstronomyTests",
            dependencies: ["SwiftAstronomy"],
            path: "Tests/SwiftAstronomyTests",
            exclude: ["SwiftAstronomyTests-Info.plist"],
            swiftSettings: [
                .interoperabilityMode(.Cxx)
            ]
        )
    ],
    cxxLanguageStandard: .cxx17
)
