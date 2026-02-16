cmake_minimum_required(VERSION 3.27)
project(SWONMacros LANGUAGES Swift)
include(FetchContent)

# Always build SWONMacros against the host machine

# Fetch the macros dependencies
FetchContent_Declare(
    SwiftSyntax
    GIT_REPOSITORY https://github.com/swiftlang/swift-syntax
    GIT_TAG edbbad240dfcc4a9a791c1e4261f52fe08342e53
)
FetchContent_MakeAvailable(SwiftSyntax)

# Build the macros with SwiftSyntax
add_executable(SWONMacros
    Decoding.swift
    Encoding.swift
    Helpers.swift
    Macros.swift
)
target_link_libraries(SWONMacros PRIVATE SwiftCompilerPlugin)
