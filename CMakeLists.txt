cmake_minimum_required(VERSION 3.27)
project(swon LANGUAGES Swift C)
include(FetchContent)

# Fetch the macros dependencies
FetchContent_Declare(
    SwiftSyntax
    GIT_REPOSITORY https://github.com/swiftlang/swift-syntax
    GIT_TAG edbbad240dfcc4a9a791c1e4261f52fe08342e53
)
FetchContent_MakeAvailable(SwiftSyntax)

# Build the macros with SwiftSyntax
file(GLOB_RECURSE SWON_SWIFT_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/Sources/SWONMacros/*.swift
)
add_executable(SWONMacros ${SWON_SWIFT_SOURCES})
target_link_libraries(SWONMacros PRIVATE
    SwiftCompilerPlugin
)

# Build the macro impl with cJSON
add_library(SWON_C STATIC
    ${CMAKE_CURRENT_SOURCE_DIR}/Sources/SWON_C/swon.c
    ${CMAKE_CURRENT_SOURCE_DIR}/Sources/SWON_C/cJSON.c
)
target_include_directories(SWON_C PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/Sources/SWON_C/include
)

# Build the macro glue with the C impl
add_library(SWON STATIC
    ${CMAKE_CURRENT_SOURCE_DIR}/Sources/SWON/SWON.swift
)
add_dependencies(SWON SWONMacros)
target_include_directories(SWON PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/Sources/SWON_C/include
)
target_compile_options(SWON PRIVATE
    -load-plugin-executable "$<TARGET_FILE:SWONMacros>#SWONMacros"
)
target_link_libraries(SWON PRIVATE SWON_C)

# Export interface
add_library(SWONInterface INTERFACE)
add_dependencies(SWONInterface SWON)
target_include_directories(SWONInterface INTERFACE
    ${CMAKE_CURRENT_BINARY_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/Sources/SWON_C/include
)
target_compile_options(SWONInterface INTERFACE
    -load-plugin-executable "$<TARGET_FILE:SWONMacros>#SWONMacros"
)
target_link_libraries(SWONInterface INTERFACE SWON)

# Sample executable
add_executable(SWONTest ${CMAKE_CURRENT_SOURCE_DIR}/main.swift)
target_link_libraries(SWONTest SWONInterface)
