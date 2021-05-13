#!/bin/bash

DEFAULT_FILE_FILTERS=( "*.cpp" "*.cc" "*.h" "*.hpp" )

################################################################################
# Print error message, usage and exit with status code if specified
################################################################################
function usage() {
    local ERROR_CODE="$1"
    local ERROR_MESSAGE="$2"

    [ -n "$ERROR_MESSAGE" ] && echo -e "Error: ${COL_RED}${ERROR_MESSAGE}${COL_RESET}\n"


    echo -e "${COL_BOLD}Usage${COL_RESET}: $0 <OPTIONS> [<FILENAME FILTER> ...]"
    echo -e ""
    echo -e "${COL_BOLD}FILENAME FILTER REGEX${COL_RESET}:"
    echo -e "    List of filter expressions used to filter files to be be formated"
    echo -e "    Filter expressions are or-ed and passed to 'find'"
    echo -e ""
    echo -e "${COL_BOLD}OPTIONS${COL_RESET}:"
    echo -e "    -d,--directory : Directory to format"
    echo -e "    -n,--dry-run   : Do not update files, but show what should be done"
    echo -e "    -h,--help      : Print usage help"
  
    if [ -n "$ERROR_CODE" ] && [ $ERROR_CODE -gt -1 ] 2> /dev/null ; then
        exit $ERROR_CODE
    fi
}

################################################################################
# Append filename filters
################################################################################
function appendFilenameFilters() {
    for FILTER in "$@" ; do
        if [ ${#FILE_FILTERS[@]} -eq 0 ] ; then
            FILE_FILTERS=( "-iname ${FILTER}" )
        else
            FILE_FILTERS+=( "-or -iname ${FILTER}" )
        fi
    done
}

################################################################################
# Parse arguments
################################################################################
while [ $# -gt 0 ] ; do
    case $1 in
        -d|--directory)  OPT_DIRECTORY="$2"; shift 1 ;;
        -n|--dry-run)    OPT_DRY_RUN="yes" ;;
        -h|--help)       usage 0 ;;
        -*)              usage 1 "Unkown option '$1'" ;;
        *)               appendFilenameFilters "$1" ;;
    esac

    shift 1
done

# Directory is mandatory
[ ! -d "${OPT_DIRECTORY}" ] && usage 1 "Missing directory name"

# If no files list specified, get all modified/untracked files from git
[ ${#FILE_FILTERS[@]} -eq 0 ] && appendFilenameFilters "${DEFAULT_FILE_FILTERS[@]}"

################################################################################
# Main
################################################################################
for FILE in $(find ${OPT_DIRECTORY} ${FILE_FILTERS[@]}) ; do
    printf "[\033[33mFORMAT\033[0m] %s\n" "${FILE}"
    [ ! -n "${OPT_DRY_RUN}" ] && clang-format --style=file -i "${FILE}"
done
