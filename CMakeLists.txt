cmake_minimum_required(VERSION 3.27)
project(SWON LANGUAGES Swift C)
include(ExternalProject)

# Build the macros plugin
ExternalProject_Add(SWONMacrosProject
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/Sources/SWONMacros
    INSTALL_COMMAND ""
)
ExternalProject_Get_Property(SWONMacrosProject BINARY_DIR)
set(MACRO_PLUGIN_DIR ${BINARY_DIR})

# Build the implementation with cJSON (Swift + C)
add_library(SWON_C STATIC
    ${CMAKE_CURRENT_SOURCE_DIR}/Sources/SWON_C/swon.c
    ${CMAKE_CURRENT_SOURCE_DIR}/Sources/SWON_C/cJSON.c
)
target_include_directories(SWON_C PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/Sources/SWON_C/include
)
add_library(SWON STATIC
    ${CMAKE_CURRENT_SOURCE_DIR}/Sources/SWON/SWON.swift
)
target_include_directories(SWON PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/Sources/SWON_C/include
)
target_link_libraries(SWON PRIVATE SWON_C)

# Depend on macros plugin
add_dependencies(SWON SWONMacrosProject)
target_compile_options(SWON PRIVATE
    -load-plugin-executable "${MACRO_PLUGIN_DIR}/SWONMacros#SWONMacros"
)

# Export interface
add_library(SWONInterface INTERFACE)
add_dependencies(SWONInterface SWON)
target_include_directories(SWONInterface INTERFACE
    ${CMAKE_CURRENT_BINARY_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/Sources/SWON_C/include
)
target_compile_options(SWONInterface INTERFACE
    -load-plugin-executable "${MACRO_PLUGIN_DIR}/SWONMacros#SWONMacros"
)
target_link_libraries(SWONInterface INTERFACE SWON)

# Sample executables
file(GLOB_RECURSE EXAMPLES_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/Examples/*.swift
)
add_executable(swon_examples ${EXAMPLES_SOURCES})
set_target_properties(swon_examples PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/bin
)
target_link_libraries(swon_examples SWONInterface)
