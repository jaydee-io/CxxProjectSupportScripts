################################################################################
##                           CxxProjectSupportScripts
##
## This file is distributed under the 3-clause Berkeley Software Distribution
## License. See LICENSE for details.
################################################################################
if(NOT DEFINED BUILD_TESTS_OPTION_NAME)
    string(TOUPPER "${CMAKE_PROJECT_NAME}_BUILD_TESTS" BUILD_TESTS_OPTION_NAME)
endif()

if(NOT ${BUILD_TESTS_OPTION_NAME})
    macro(enable_unit_test)
    endmacro()
    function(add_unit_test)
    endfunction()

    message(STATUS "Enabling unit tests for '${CMAKE_PROJECT_NAME}': no")

    return()
endif()

message(STATUS "Enabling unit tests for '${CMAKE_PROJECT_NAME}': yes")

macro(find_googletest)
    # First, try the system wide installation
    find_package(GTest)
    if(GTEST_FOUND)
        set(UNIT_TESTS_LIBS GTest::GTest GTest::Main CACHE INTERNAL "INTERNAL Unit tests libraries to link")
    # If not available, try fetching from github
    else()
        message(STATUS "Fetching GoogleTest from GitHub")
        include(FetchContent)

        FetchContent_Declare(
            googletest
            GIT_REPOSITORY https://github.com/google/googletest.git
            GIT_TAG        release-1.11.0
            GIT_SHALLOW    ON
            GIT_PROGRESS   ON
        )
        
        FetchContent_GetProperties(googletest)
        if(NOT googletest_POPULATED)
            FetchContent_Populate(googletest)
            add_subdirectory(${googletest_SOURCE_DIR} ${googletest_BINARY_DIR})
        endif()
        message(STATUS "Fetching GoogleTest from GitHub - done")

        include(GoogleTest)
        set(UNIT_TESTS_LIBS gtest gmock gtest_main CACHE INTERNAL "INTERNAL Unit tests libraries to link")
    endif()
endmacro()

macro(enable_unit_test)
    find_googletest()
    enable_testing()
endmacro()

function(add_unit_test TEST_TARGET)
    add_executable(${TEST_TARGET} ${ARGN})
    target_link_libraries(${TEST_TARGET} PRIVATE ${UNIT_TESTS_LIBS})
    gtest_discover_tests(${TEST_TARGET} EXTRA_ARGS --gtest_color=yes)
    if(COMMAND target_code_coverage)
        target_code_coverage(${TEST_TARGET} EXCLUDE ${ARGN})
    endif()
endfunction()
