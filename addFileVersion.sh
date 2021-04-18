#!/bin/bash
################################################################################
##                           CxxProjectSupportScripts
##
## This file is distributed under the 3-clause Berkeley Software Distribution
## License. See LICENSE for details.
################################################################################
source "$(dirname "$0")/scripts/lib-global-constants.sh"
source "${DIR_LIBS}/lib-utils.sh"
source "${DIR_LIBS}/lib-file-versioning.sh"

################################################################################
# Print error message, usage and exit with status code if specified
################################################################################
function usage() {
    local ERROR_CODE="$1"
    local ERROR_MESSAGE="$2"

    [ -n "$ERROR_MESSAGE" ] && echo -e "Error: ${COL_RED}${ERROR_MESSAGE}${COL_RESET}\n"


    echo -e "${COL_BOLD}Usage${COL_RESET}: $0 <OPTIONS> <FILES TO ADD>"
    echo -e ""
    echo -e "${COL_BOLD}OPTIONS${COL_RESET}:"
    echo -e "    -c,--commit  : Commit the updated project files"
    echo -e "    -n,--dry-run : Do not update files, but show what should be done"
    echo -e "    -h,--help    : Print usage help"

    if [ -n "$ERROR_CODE" ] && [ $ERROR_CODE -gt -1 ] 2> /dev/null ; then
        exit $ERROR_CODE
    fi
}

################################################################################
# Use git to list all files 
################################################################################
function gitListFilesToAdd() {
    git -C "${DIR_BASE}" status -s "${DIR_ROOT_FS_SHORT}" | while read LINE ; do
        trimLeft "${LINE}" 2
    done
}

################################################################################
# Normalize filename ($1)
################################################################################
function normalizeFilename() {
    local VAR_FILENAME="$1"
    local FILENAME="${!VAR_FILENAME}"
    local NEW_FILENAME

    # Filename relative to CxxProjectSupportScripts root directory
    if [ -f "${DIR_BASE}/${FILENAME}" ] ; then
        eval $VAR_FILENAME="${FILENAME}"
        return 0
    fi
    # Filename relative to CxxProjectSupportScripts filesystem root directory
    if [ -f "${DIR_BASE}/${DIR_ROOT_FS_SHORT}/${FILENAME}" ] ; then
        eval $VAR_FILENAME="${DIR_ROOT_FS_SHORT}/${FILENAME}"
        return 0
    fi

    local FILES_IN_ROOT_FS=( $(cd "${DIR_BASE}" ; find . -iname "$(basename "${FILENAME}")") )

    # Only file found in CxxProjectSupportScripts filesystem root directory
    if [ ${#FILES_IN_ROOT_FS[@]} -eq 1 ] ; then
        eval $VAR_FILENAME="$(trimLeft "${FILES_IN_ROOT_FS[0]}" 2)"
        return 0
    fi

    # Multiple files found in CxxProjectSupportScripts filesystem root directory
    if [ ${#FILES_IN_ROOT_FS[@]} -gt 1 ] ; then
        echo "Multiple files match '${FILENAME}':"
        for I in "${!FILES_IN_ROOT_FS[@]}" ; do
            printf " %2d - %s\n" "${I}" "${FILES_IN_ROOT_FS[${I}]}"
        done
        printf "Select file to update: "
        read FILE_INDEX
        if [ -n "$FILE_INDEX" ] && [ $FILE_INDEX -ge 0 ] 2> /dev/null && [ $FILE_INDEX -lt ${#FILES_IN_ROOT_FS[@]} ] 2> /dev/null ; then
            eval $VAR_FILENAME="$(trimLeft "${FILES_IN_ROOT_FS[${FILE_INDEX}]}" 2)"
            return 0
        fi
    fi

    # Multiple files found in CxxProjectSupportScripts filesystem root directory
    return 1
}

################################################################################
# Parse arguments
################################################################################
while [ $# -gt 0 ] ; do
    case $1 in
        -c|--commit)  OPT_COMMIT="yes" ;;
        -n|--dry-run) OPT_DRY_RUN="yes" ;;
        -h|--help)    usage 0 ;;
        -*)           usage 1 "Unkown option '$1'" ;;
        *)            FILES_TO_ADD+=("$1") ;;
    esac

    shift 1
done

################################################################################
# Main
################################################################################
# If no files list specified, get all modified/untracked files from git
[ ${#FILES_TO_ADD[@]} -eq 0 ] && FILES_TO_ADD=( $(gitListFilesToAdd) )

# Prepare commit message
[ -n "${OPT_COMMIT}" ] && [ ! -f "${FILE_COMMIT_MSG}" ] && addToCommitMessage "Updated configuration files\n\nList of changes:"

# Process each file
for FILE in "${FILES_TO_ADD[@]}" ; do
    if ! normalizeFilename FILE ; then
        echo -e "${COL_RED}No file matching '${FILE}' found!${COL_RESET}"
        continue
    fi
    addFileVersion "${DIR_BASE}/${FILE}"
done

# Commit changes
if [ -n "${OPT_COMMIT}" ] && [ ! -n "${OPT_DRY_RUN}" ] ; then
    addFileTocommit "${DIR_BASE}" "${FILE_VERSIONS##.*/}"
    commitChanges "${DIR_BASE}"
    removeCommitMessageFile
fi