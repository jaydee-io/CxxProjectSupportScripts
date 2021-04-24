################################################################################
##                           CxxProjectSupportScripts
##
## This file is distributed under the 3-clause Berkeley Software Distribution
## License. See LICENSE for details.
################################################################################

################################################################################
# Update project file ($1)
################################################################################
function updateProjectFile() {
    local FILE="$1"
    local FILE_HASH="$(hashFile "${OPT_DIR_PROJECT}/${FILE}")"
    local FILE_HASH_SHORT="${FILE_HASH:0:8}"
    local TIMESTAMP="$(date +%s)"

    # Get file lastest version and date
    if ! getFileLatestVersion "${FILE}" FILE_LATEST_HASH FILE_LATEST_DATE ; then
        echo -e "${COL_RED}File '${FILE}' not found in database!${COL_RESET}"
        return 1
    fi
    local FILE_LATEST_HASH_SHORT="${FILE_LATEST_HASH:0:8}"
    local FILE_LATEST_DATE_READABLE="$(date -j -f %s "${FILE_LATEST_DATE}" +%d/%m/%Y)"

    # File exists in project, update
    if [ -n "${FILE_HASH}" ] ; then
        if getFileVersion "${FILE}" "${FILE_HASH}" FILE_DATE ; then
            local FILE_DATE_READABLE="$(date -j -f %s "${FILE_DATE}" +%d/%m/%Y)"
        else
            local FILE_DATE_READABLE="${COL_YELLOW}Unknown version${COL_RESET}"
        fi
        MESSAGE="Updated file '${COL_GREEN}${FILE}${COL_RESET}' from version [${COL_YELLOW}${FILE_HASH_SHORT}${COL_RESET}] (${FILE_DATE_READABLE}) to [${COL_YELLOW}${FILE_LATEST_HASH_SHORT}${COL_RESET}] (${FILE_LATEST_DATE_READABLE})"
    # New file
    else
        MESSAGE="Added new file '${COL_GREEN}${FILE}${COL_RESET}' with initial version [${COL_YELLOW}${FILE_LATEST_HASH_SHORT}${COL_RESET}] (${FILE_LATEST_DATE_READABLE})"
    fi

    # Update file
    if [ ! -n "${OPT_DRY_RUN}" ] ; then
        # Create directory first if it doesn't exists
        local BASE_DIR=$(dirname "${OPT_DIR_PROJECT}/${FILE}")
        mkdir -p "${BASE_DIR}"

        cp "${DIR_ROOT_FS}/${FILE}" "${OPT_DIR_PROJECT}/${FILE}"
    fi

    # Display and prepare commit message
    echo -e "${MESSAGE}"
    [ -n "${OPT_COMMIT}" ] && addToCommitMessage "* $(echo -e "${MESSAGE}" | sed $'s/\033\\[[^m]*m//g')"

    # Commit file
    [ -n "${OPT_COMMIT}" ] && [ ! -n "${OPT_DRY_RUN}" ] && addFileTocommit "${OPT_DIR_PROJECT}" "${FILE}"
}

################################################################################
# Add new version of file ($1)
################################################################################
function addFileVersion() {
    local FILE="$1"
    local FILE_RELATIVE_TO_ROOT_FS="${FILE##.*root/}"
    local FILE_HASH="$(hashFile "${FILE}")"
    local FILE_HASH_SHORT="${FILE_HASH:0:8}"
    local TIMESTAMP="$(date +%s)"

    # Get file current version and date
    # File exists, update
    if getFileLatestVersion "${FILE_RELATIVE_TO_ROOT_FS}" FILE_LATEST_HASH FILE_LATEST_DATE ; then
        local FILE_LATEST_HASH_SHORT="${FILE_LATEST_HASH:0:8}"
        local FILE_LATEST_DATE_READABLE="$(date -j -f %s "${FILE_LATEST_DATE}" +%d/%m/%Y)"
        MESSAGE="Update file '${COL_GREEN}${FILE_RELATIVE_TO_ROOT_FS}${COL_RESET}' from version [${COL_YELLOW}${FILE_LATEST_HASH_SHORT}${COL_RESET}] (${FILE_LATEST_DATE_READABLE}) to [${COL_YELLOW}${FILE_HASH_SHORT}${COL_RESET}]"
    # New file
    else
        MESSAGE="Add new file '${COL_GREEN}${FILE_RELATIVE_TO_ROOT_FS}${COL_RESET}' with initial version [${COL_YELLOW}${FILE_HASH_SHORT}${COL_RESET}]"
    fi

    # Display and prepare commit message
    echo -e "${MESSAGE}"
    [ -n "${OPT_COMMIT}" ] && addToCommitMessage "* $(echo -e "${MESSAGE}" | sed $'s/\033\\[[^m]*m//g')"

    # Update version database
    [ ! -n "${OPT_DRY_RUN}" ] && insertLineAt "${FILE_VERSIONS}" 1 "${TIMESTAMP};${FILE_HASH};${FILE_RELATIVE_TO_ROOT_FS}"

    # Add file to cmmit
    [ -n "${OPT_COMMIT}" ] && [ ! -n "${OPT_DRY_RUN}" ] && addFileTocommit "${DIR_BASE}" "${DIR_ROOT_FS_SHORT}/${FILE_RELATIVE_TO_ROOT_FS}"
}

################################################################################
# Hash file ($1)
################################################################################
function hashFile() {
    local FILE="$1"

    [ -f "${FILE}" ] && ${BIN_CHECKSUM} "${FILE}" | cut -d " " -f 1
}

################################################################################
# Get file ($1) latest version
################################################################################
function getFileLatestVersion() {
    local FILE="$1"
    local VAR_HASH="$2"
    local VAR_DATE="$3"

    [ ! -f "${FILE_VERSIONS}" ] && return 1

    local LINE="$(grep "${FILE}" "${FILE_VERSIONS}" | head -n 1)"
    [ -z "${LINE}" ] && return 1

    eval $VAR_DATE=$(cut -d ";" -f 1 <<< "$LINE")
    eval $VAR_HASH=$(cut -d ";" -f 2 <<< "$LINE")

    return 0
}

################################################################################
# Get file ($1) version (hash in $2)
################################################################################
function getFileVersion() {
    local FILE="$1"
    local HASH="$2"
    local VAR_DATE="$3"

    [ ! -f "${FILE_VERSIONS}" ] && return 1

    local LINE="$(grep "${HASH}.*${FILE}" "${FILE_VERSIONS}" | head -n 1)"

    [ ! -n "$LINE" ] && return 1

    eval $VAR_DATE=$(cut -d ";" -f 1 <<< "$LINE")

    return 0
}
