################################################################################
##                           CxxProjectSupportScripts
##
## This file is distributed under the 3-clause Berkeley Software Distribution
## License. See LICENSE for details.
################################################################################
# Adapted from George Cave cmake-scripts/code-coverage.cmake script
# See https://github.com/StableCoder/cmake-scripts/blob/main/code-coverage.cmake
################################################################################
if(NOT DEFINED CODE_COVERAGE_OPTION_NAME)
    string(TOUPPER "${CMAKE_PROJECT_NAME}_CODE_COVERAGE" CODE_COVERAGE_OPTION_NAME)
endif()

if(NOT ${CODE_COVERAGE_OPTION_NAME})
    macro(enable_code_coverage)
    endmacro()
    function(target_code_coverage)
    endfunction()

    message(STATUS "Enabling code coverage for '${CMAKE_PROJECT_NAME}': no")

    return()
endif()

message(STATUS "Enabling code coverage for '${CMAKE_PROJECT_NAME}': yes")

################################################################################
# Enable code coverage
# (Must be called before adding coverage to target)
################################################################################
macro(enable_code_coverage)
    # Check supported toolchains
    check_compiler(CODE_COVERAGE_WITH_CLANG "(Apple)?[Cc]lang")
    check_compiler(CODE_COVERAGE_WITH_GCC   "GNU")

    set(CODE_COVERAGE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/code-coverage)

    # Common setup
    add_custom_target(code-coverage-create-output-directory
        COMMAND ${CMAKE_COMMAND} -E make_directory ${CODE_COVERAGE_OUTPUT_DIRECTORY}
        DEPENDS code-coverage-clean
    )
    add_custom_target(code-coverage)

    # Setup coverage with specific toolchain
    if(CODE_COVERAGE_WITH_CLANG)
        setup_coverage_with_llvmcov()
    elseif(CODE_COVERAGE_WITH_GCC)
        setup_coverage_with_gcov()
    else()
        message(FATAL_ERROR "Code coverage not suppported with '${CMAKE_CXX_COMPILER_ID}' toolchain")
    endif()

    add_custom_command(TARGET code-coverage-all
        POST_BUILD
        COMMAND ;
        COMMENT "Open ${CODE_COVERAGE_OUTPUT_DIRECTORY}/all-merged/index.html in your browser to view the coverage report."
    )
endmacro()

################################################################################
# Add code coverage to specified target
################################################################################
function(target_code_coverage TARGET_NAME)
    # Argument parsing
    cmake_parse_arguments(TARGET_CODE_COVERAGE "PUBLIC;INTERFACE" "COVERAGE_TARGET_NAME" "EXCLUDE;OBJECTS;ARGS" ${ARGN})

    # Set the visibility of target functions to PUBLIC, INTERFACE or default to PRIVATE
    if(TARGET_CODE_COVERAGE_PUBLIC)
        set(TARGET_VISIBILITY PUBLIC)
    elseif(TARGET_CODE_COVERAGE_INTERFACE)
        set(TARGET_VISIBILITY INTERFACE)
    else()
        set(TARGET_VISIBILITY PRIVATE)
    endif()

    if(NOT TARGET_CODE_COVERAGE_COVERAGE_TARGET_NAME)
        # If a specific name was given, use that instead.
        set(TARGET_CODE_COVERAGE_COVERAGE_TARGET_NAME ${TARGET_NAME})
    endif()

    # Add code coverage instrumentation to the target's linker command
    if(CODE_COVERAGE_WITH_CLANG)
        target_compile_options(${TARGET_NAME} ${TARGET_VISIBILITY} -fprofile-instr-generate -fcoverage-mapping)
        target_link_options   (${TARGET_NAME} ${TARGET_VISIBILITY} -fprofile-instr-generate -fcoverage-mapping)
    elseif(CODE_COVERAGE_WITH_GCC)
        target_compile_options(${TARGET_NAME} ${TARGET_VISIBILITY} -fprofile-arcs -ftest-coverage)
        target_link_libraries (${TARGET_NAME} ${TARGET_VISIBILITY} gcov)
    endif()

    # Targets
    get_target_property(TARGET_TYPE ${TARGET_NAME} TYPE)

    # Add shared library to processing for 'all' targets (clang only)
    if(TARGET_TYPE STREQUAL "SHARED_LIBRARY" AND CODE_COVERAGE_WITH_CLANG)
        add_custom_target(code-coverage-run-${TARGET_CODE_COVERAGE_COVERAGE_TARGET_NAME}
            COMMAND echo "-object=$<TARGET_FILE:${TARGET_NAME}>" >> ${CODE_COVERAGE_OUTPUT_DIRECTORY}/binaries.list
            DEPENDS code-coverage-create-output-directory ${TARGET_NAME}
        )

        add_dependencies(code-coverage-libs code-coverage-run-${TARGET_CODE_COVERAGE_COVERAGE_TARGET_NAME})
    endif()

    # For executables add targets to run and produce output
    if(TARGET_TYPE STREQUAL "EXECUTABLE")
        if(CODE_COVERAGE_WITH_CLANG)
            # If there are shared objects to also work with, generate the string to add them here
            foreach(SO_TARGET ${TARGET_CODE_COVERAGE_OBJECTS})
                # Check to see if the target is a shared object
                if(TARGET ${SO_TARGET})
                    get_target_property(SO_TARGET_TYPE ${SO_TARGET} TYPE)
                    if(${SO_TARGET_TYPE} STREQUAL "SHARED_LIBRARY")
                        set(SO_OBJECTS ${SO_OBJECTS} -object=$<TARGET_FILE:${SO_TARGET}>)
                    endif()
                endif()
            endforeach()

            # Exclude files from coverage
            foreach(EXCLUDE_ITEM ${TARGET_CODE_COVERAGE_EXCLUDE})
                set(EXCLUDE_REGEX ${EXCLUDE_REGEX} -ignore-filename-regex='${EXCLUDE_ITEM}')
            endforeach()

            # Run the executable, generating raw profile data
            add_custom_target(code-coverage-run-${TARGET_CODE_COVERAGE_COVERAGE_TARGET_NAME}
                COMMAND LLVM_PROFILE_FILE=${TARGET_CODE_COVERAGE_COVERAGE_TARGET_NAME}.profraw $<TARGET_FILE:${TARGET_NAME}> ${TARGET_CODE_COVERAGE_ARGS}
                COMMAND echo "-object=$<TARGET_FILE:${TARGET_NAME}>" ${SO_OBJECTS} >> ${CODE_COVERAGE_OUTPUT_DIRECTORY}/binaries.list
                COMMAND echo "${CMAKE_CURRENT_BINARY_DIR}/${TARGET_CODE_COVERAGE_COVERAGE_TARGET_NAME}.profraw" >> ${CODE_COVERAGE_OUTPUT_DIRECTORY}/profraw.list
                COMMAND echo ${EXCLUDE_REGEX} >> ${CODE_COVERAGE_OUTPUT_DIRECTORY}/exclude_regex.list
                DEPENDS code-coverage-create-output-directory code-coverage-libs ${TARGET_NAME}
            )

            # Merge the generated profile data so llvm-cov can process it
            add_custom_target(code-coverage-processing-${TARGET_CODE_COVERAGE_COVERAGE_TARGET_NAME}
                COMMAND ${CODE_COVERAGE_LLVM_PROFDATA_PATH} merge -sparse
                        ${TARGET_CODE_COVERAGE_COVERAGE_TARGET_NAME}.profraw -o
                        ${TARGET_CODE_COVERAGE_COVERAGE_TARGET_NAME}.profdata
                DEPENDS code-coverage-run-${TARGET_CODE_COVERAGE_COVERAGE_TARGET_NAME}
            )

            # Print out details of the coverage information to the command line
            add_custom_target(code-coverage-show-${TARGET_CODE_COVERAGE_COVERAGE_TARGET_NAME}
                COMMAND ${CODE_COVERAGE_LLVM_COV_PATH} show $<TARGET_FILE:${TARGET_NAME}> ${SO_OBJECTS}
                        -instr-profile=${TARGET_CODE_COVERAGE_COVERAGE_TARGET_NAME}.profdata
                        -show-line-counts-or-regions ${EXCLUDE_REGEX}
                DEPENDS code-coverage-processing-${TARGET_CODE_COVERAGE_COVERAGE_TARGET_NAME}
            )

            # Print out a summary of the coverage information to the command line
            add_custom_target(code-coverage-report-${TARGET_CODE_COVERAGE_COVERAGE_TARGET_NAME}
                COMMAND ${CODE_COVERAGE_LLVM_COV_PATH} report $<TARGET_FILE:${TARGET_NAME}> ${SO_OBJECTS}
                        -instr-profile=${TARGET_CODE_COVERAGE_COVERAGE_TARGET_NAME}.profdata
                        ${EXCLUDE_REGEX}
                DEPENDS code-coverage-processing-${TARGET_CODE_COVERAGE_COVERAGE_TARGET_NAME}
            )

            # Generates HTML output of the coverage information for perusal
            add_custom_target(code-coverage-${TARGET_CODE_COVERAGE_COVERAGE_TARGET_NAME}
                COMMAND ${CODE_COVERAGE_LLVM_COV_PATH} show $<TARGET_FILE:${TARGET_NAME}> ${SO_OBJECTS}
                    -instr-profile=${TARGET_CODE_COVERAGE_COVERAGE_TARGET_NAME}.profdata
                    -show-line-counts-or-regions
                    -output-dir=${CODE_COVERAGE_OUTPUT_DIRECTORY}/${TARGET_CODE_COVERAGE_COVERAGE_TARGET_NAME}
                    -format="html"
                    ${EXCLUDE_REGEX}
                DEPENDS code-coverage-processing-${TARGET_CODE_COVERAGE_COVERAGE_TARGET_NAME}
            )

        elseif(CODE_COVERAGE_WITH_GCC)
            set(COVERAGE_INFO "${CODE_COVERAGE_OUTPUT_DIRECTORY}/${TARGET_CODE_COVERAGE_COVERAGE_TARGET_NAME}.info")

            # Generate exclusion string for use
            foreach(EXCLUDE_ITEM ${TARGET_CODE_COVERAGE_EXCLUDE})
                set(EXCLUDE_REGEX ${EXCLUDE_REGEX} --remove ${COVERAGE_INFO} '*${EXCLUDE_ITEM}*')
                set(GLOBAL_EXCLUDE_REGEX ${GLOBAL_EXCLUDE_REGEX} --remove ${GLOBAL_COVERAGE_INFO} '*${EXCLUDE_ITEM}*')
            endforeach()

            if(EXCLUDE_REGEX)
                set(EXCLUDE_COMMAND ${CODE_COVERAGE_LCOV_PATH} ${EXCLUDE_REGEX} --output-file ${COVERAGE_INFO})
            else()
                set(EXCLUDE_COMMAND ;)
            endif()

            # Run the executable, generating coverage information
            add_custom_target(code-coverage-run-${TARGET_CODE_COVERAGE_COVERAGE_TARGET_NAME}
                COMMAND $<TARGET_FILE:${TARGET_NAME}> ${TARGET_CODE_COVERAGE_ARGS}
                COMMAND echo ${GLOBAL_EXCLUDE_REGEX} >> ${CODE_COVERAGE_OUTPUT_DIRECTORY}/exclude_regex.list
                DEPENDS code-coverage-create-output-directory ${TARGET_NAME}
            )

            # Capture coverage data
            add_custom_target(code-coverage-capture-${TARGET_CODE_COVERAGE_COVERAGE_TARGET_NAME}
                COMMAND ${CMAKE_COMMAND} -E remove ${COVERAGE_INFO}
                COMMAND ${CODE_COVERAGE_LCOV_PATH} --directory ${CMAKE_BINARY_DIR} --zerocounters
                COMMAND $<TARGET_FILE:${TARGET_NAME}> ${TARGET_CODE_COVERAGE_ARGS}
                COMMAND ${CODE_COVERAGE_LCOV_PATH} --directory ${CMAKE_BINARY_DIR} --base-directory ${CMAKE_SOURCE_DIR} --capture --no-external --output-file ${COVERAGE_INFO}
                COMMAND ${EXCLUDE_COMMAND}
                DEPENDS code-coverage-create-output-directory ${TARGET_NAME}
            )

            # Generates HTML output of the coverage information for perusal
            add_custom_target(code-coverage-${TARGET_CODE_COVERAGE_COVERAGE_TARGET_NAME}
                COMMAND ${CODE_COVERAGE_GENHTML_PATH} --demangle-cpp -o ${CODE_COVERAGE_OUTPUT_DIRECTORY}/${TARGET_CODE_COVERAGE_COVERAGE_TARGET_NAME} ${COVERAGE_INFO}
                DEPENDS code-coverage-capture-${TARGET_CODE_COVERAGE_COVERAGE_TARGET_NAME}
            )
        endif()

        add_custom_command(TARGET code-coverage-${TARGET_CODE_COVERAGE_COVERAGE_TARGET_NAME}
            POST_BUILD
            COMMAND ;
            COMMENT "Open ${CODE_COVERAGE_OUTPUT_DIRECTORY}/${TARGET_CODE_COVERAGE_COVERAGE_TARGET_NAME}/index.html in your browser to view the coverage report."
        )

        # Add to global targets
        add_dependencies(code-coverage-all-processing code-coverage-run-${TARGET_CODE_COVERAGE_COVERAGE_TARGET_NAME})
        add_dependencies(code-coverage code-coverage-${TARGET_CODE_COVERAGE_COVERAGE_TARGET_NAME})
        if(CODE_COVERAGE_WITH_CLANG)
            add_dependencies(code-coverage-report code-coverage-report-${TARGET_CODE_COVERAGE_COVERAGE_TARGET_NAME})
        endif()
    endif()
endfunction()



################################################################################
# Internal utility fonctions
# Do not call directly
################################################################################
macro(check_compiler VARIABLE EXPRESSION)
    if(CMAKE_C_COMPILER_ID MATCHES ${EXPRESSION} OR CMAKE_CXX_COMPILER_ID MATCHES ${EXPRESSION})
        set(${VARIABLE} ON)
    endif()
endmacro()

macro(setup_coverage_with_llvmcov)
    # Find llvm-cov binaries
    set(MACOS_TOOLS_PATH "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin")
    find_program(CODE_COVERAGE_LLVM_COV_PATH      NAMES llvm-cov      HINTS ${MACOS_TOOLS_PATH})
    find_program(CODE_COVERAGE_LLVM_PROFDATA_PATH NAMES llvm-profdata HINTS ${MACOS_TOOLS_PATH})
    mark_as_advanced(FORCE CODE_COVERAGE_LLVM_COV_PATH CODE_COVERAGE_LLVM_PROFDATA_PATH)

    if(NOT CODE_COVERAGE_LLVM_COV_PATH)
        message(FATAL_ERROR "Code coverage error: 'llvm-cov' not found! Aborting.")
    endif()
    if(NOT CODE_COVERAGE_LLVM_PROFDATA_PATH)
        message(FATAL_ERROR "Code coverage error: 'llvm-profdata' not found! Aborting.")
    endif()

    # Clean coverage
    add_custom_target(code-coverage-clean
        COMMAND rm -f ${CODE_COVERAGE_OUTPUT_DIRECTORY}/binaries.list
        COMMAND rm -f ${CODE_COVERAGE_OUTPUT_DIRECTORY}/profraw.list
        COMMAND rm -f ${CODE_COVERAGE_OUTPUT_DIRECTORY}/exclude_regex.list
    )

    # Global report target
    add_custom_target(code-coverage-report)

    # Used to get the shared object file list before doing the main all-processing
    add_custom_target(code-coverage-libs COMMAND ; COMMENT "libs ready for coverage report.")

    # Merge the profile data for all of the run executables
    add_custom_target(code-coverage-all-processing
        COMMAND ${CODE_COVERAGE_LLVM_PROFDATA_PATH} merge
            -o ${CODE_COVERAGE_OUTPUT_DIRECTORY}/all-merged.profdata
            -sparse
            `cat ${CODE_COVERAGE_OUTPUT_DIRECTORY}/profraw.list`
    )

    # Print summary of the code coverage information to the command line
    add_custom_target(code-coverage-all-report
        COMMAND ${CODE_COVERAGE_LLVM_COV_PATH} report
            `cat ${CODE_COVERAGE_OUTPUT_DIRECTORY}/binaries.list`
            -instr-profile=${CODE_COVERAGE_OUTPUT_DIRECTORY}/all-merged.profdata
            `cat ${CODE_COVERAGE_OUTPUT_DIRECTORY}/exclude_regex.list`
        DEPENDS code-coverage-all-processing
    )

    # Export coverage information so continuous integration tools (e.g. Jenkins) can consume it
    add_custom_target(code-coverage-all-export
        COMMAND ${CODE_COVERAGE_LLVM_COV_PATH} export `cat ${CODE_COVERAGE_OUTPUT_DIRECTORY}/binaries.list`
            -instr-profile=${CODE_COVERAGE_OUTPUT_DIRECTORY}/all-merged.profdata
            -format="text"
            `cat ${CODE_COVERAGE_OUTPUT_DIRECTORY}/exclude_regex.list`
            > ${CODE_COVERAGE_OUTPUT_DIRECTORY}/coverage.json
        DEPENDS code-coverage-all-processing
    )

    # Generate HTML output of all added targets for perusal
    add_custom_target(code-coverage-all
        COMMAND ${CODE_COVERAGE_LLVM_COV_PATH} show `cat ${CODE_COVERAGE_OUTPUT_DIRECTORY}/binaries.list`
            -instr-profile=${CODE_COVERAGE_OUTPUT_DIRECTORY}/all-merged.profdata
            -show-line-counts-or-regions
            -output-dir=${CODE_COVERAGE_OUTPUT_DIRECTORY}/all-merged
            -format="html"
            `cat ${CODE_COVERAGE_OUTPUT_DIRECTORY}/exclude_regex.list`
        DEPENDS code-coverage-all-processing
    )
endmacro()

macro(setup_coverage_with_gcov)
    # Find gcov binaries
    find_program(CODE_COVERAGE_LCOV_PATH    lcov)
    find_program(CODE_COVERAGE_GENHTML_PATH genhtml)
    mark_as_advanced(FORCE CODE_COVERAGE_LCOV_PATH CODE_COVERAGE_GENHTML_PATH)

    if(NOT CODE_COVERAGE_LCOV_PATH)
        message(FATAL_ERROR "Code coverage error: 'lcov' not found! Aborting.")
    endif()
    if(NOT CODE_COVERAGE_GENHTML_PATH)
        message(FATAL_ERROR "Code coverage error: 'genhtml' not found! Aborting.")
    endif()

    # Clean coverage
    add_custom_target(code-coverage-clean
        COMMAND ${CODE_COVERAGE_LCOV_PATH} --directory ${CMAKE_BINARY_DIR} --zerocounters
        COMMAND rm -f ${CODE_COVERAGE_OUTPUT_DIRECTORY}/exclude_regex.list
    )
    
    set(GLOBAL_COVERAGE_INFO "${CODE_COVERAGE_OUTPUT_DIRECTORY}/all-merged.info")

    # Nothing required for gcov
    add_custom_target(code-coverage-all-processing COMMAND ;)

    # Capture coverage data
    add_custom_target(code-coverage-all-capture
        COMMAND ${CMAKE_COMMAND} -E remove ${GLOBAL_COVERAGE_INFO}
        COMMAND ${CODE_COVERAGE_LCOV_PATH} --directory ${CMAKE_BINARY_DIR} --base-directory ${CMAKE_SOURCE_DIR} --capture --no-external --output-file ${GLOBAL_COVERAGE_INFO}
        COMMAND [ `wc -c < ${CODE_COVERAGE_OUTPUT_DIRECTORY}/exclude_regex.list` -gt 0 ] &&
                ${CODE_COVERAGE_LCOV_PATH} `cat ${CODE_COVERAGE_OUTPUT_DIRECTORY}/exclude_regex.list`
                --no-external --output-file ${GLOBAL_COVERAGE_INFO}
        DEPENDS code-coverage-all-processing
    )

    # Generates HTML output of all targets for perusal
    add_custom_target(code-coverage-all
        COMMAND ${CODE_COVERAGE_GENHTML_PATH} --demangle-cpp -o ${CODE_COVERAGE_OUTPUT_DIRECTORY}/all-merged ${GLOBAL_COVERAGE_INFO}
        DEPENDS code-coverage-all-capture
    )
endmacro()
