################################################################################
##                           CxxProjectSupportScripts
##
## This file is distributed under the 3-clause Berkeley Software Distribution
## License. See LICENSE for details.
################################################################################

################################################################################
# Globals
################################################################################
TAG_TEMPLATE="TAG TEMPLATE"

################################################################################
# Update project file ($1)
################################################################################
function updateProjectFile() {
    local FILE_ID="$1"
    local FILE_HASH="$(hashFile "${OPT_DIR_PROJECT}/${FILE_ID}")"

    # Get file lastest version (hash) and date
    if ! getFileLatestVersion "${FILE_ID}" FILE_LATEST_HASH FILE_LATEST_DATE ; then
        echo -e "${COL_RED}File '${FILE_ID}' not found in database!${COL_RESET}"
        return 1
    fi

    # Check if file is up to date
    isFileUpToDate "${FILE_ID}" "${FILE_HASH}" "${FILE_LATEST_HASH}" "${FILE_LATEST_DATE}" && return    
    
    # Pepare and display commit message
    prepareAndPrintCommitMessage "${FILE_ID}" "${FILE_HASH}" "${FILE_LATEST_HASH}" "${FILE_LATEST_DATE}"

    if [ ! -n "${OPT_DRY_RUN}" ] ; then
        # Update file
        copyReferenceFileToProject "${FILE_ID}"

        # Add file to commit
        [ -n "${OPT_COMMIT}" ] && addFileTocommit "${OPT_DIR_PROJECT}" "${FILE_ID}"
    fi
}

################################################################################
# Update templated project file ($1)
################################################################################
function updateTemplatedProjectFile() {
    local FILE_ID="$1"
    local FILE_IN_PROJECT="${OPT_DIR_PROJECT}/${FILE_ID}"
    local FILE_TMP="$(mktemp)"

    # Get file lastest version (hash) and date
    if ! getFileLatestVersion "${FILE_ID}" FILE_LATEST_HASH FILE_LATEST_DATE ; then
        echo -e "${COL_RED}File '${FILE_ID}' not found in database!${COL_RESET}"
        return 1
    fi

    # Restore project instanciated file into temporary file and get hash
    if [ -f "${FILE_IN_PROJECT}" ] ; then
        cp "${FILE_IN_PROJECT}" "${FILE_TMP}"
        restoreTemplatedFile "${FILE_TMP}"
        FILE_HASH="$(hashFile "${FILE_TMP}")"
        rm -f "${FILE_TMP}"
    fi

    # Check if file is up to date
    isFileUpToDate "${FILE_ID}" "${FILE_HASH}" "${FILE_LATEST_HASH}" "${FILE_LATEST_DATE}" && return

    # Pepare and display commit message
    prepareAndPrintCommitMessage "${FILE_ID}" "${FILE_HASH}" "${FILE_LATEST_HASH}" "${FILE_LATEST_DATE}"

    if [ ! -n "${OPT_DRY_RUN}" ] ; then
        # Update file
        copyReferenceFileToProject "${FILE_ID}"

        # Instanciate template
        affectTemplateVariableInFile "${FILE_IN_PROJECT}" PROJECT "${GITHUB_PROJECT}"

        # Add file to commit
        [ -n "${OPT_COMMIT}" ] && addFileTocommit "${OPT_DIR_PROJECT}" "${FILE_ID}"
    fi
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
        local FILE_LATEST_DATE_READABLE="$(timestampToDate "${FILE_LATEST_DATE}")"
        MESSAGE="Update file '${COL_GREEN}${FILE_RELATIVE_TO_ROOT_FS}${COL_RESET}' from version [${COL_YELLOW}${FILE_LATEST_HASH_SHORT}${COL_RESET}] (${FILE_LATEST_DATE_READABLE}) to [${COL_YELLOW}${FILE_HASH_SHORT}${COL_RESET}]"
    # New file
    else
        MESSAGE="Add new file '${COL_GREEN}${FILE_RELATIVE_TO_ROOT_FS}${COL_RESET}' with initial version [${COL_YELLOW}${FILE_HASH_SHORT}${COL_RESET}]"
    fi

    # Check if file is up to date
    isFileUpToDate "${FILE}" "${FILE_HASH}" "${FILE_LATEST_HASH}" "${FILE_LATEST_DATE}" && return

    # Display and prepare commit message
    echo -e "${MESSAGE}"
    [ -n "${OPT_COMMIT}" ] && [ ! -n "${OPT_DRY_RUN}" ] && addToCommitMessage "* $(filterColor "${MESSAGE}")"

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
# Get date of a file ($1) of specific version (hash in $2)
################################################################################
function getFileDate() {
    local FILE="$1"
    local HASH="$2"
    local VAR_DATE="$3"

    [ ! -f "${FILE_VERSIONS}" ] && return 1

    local LINE="$(grep "${HASH}.*${FILE}" "${FILE_VERSIONS}" | head -n 1)"

    [ ! -n "$LINE" ] && return 1

    eval $VAR_DATE=$(cut -d ";" -f 1 <<< "$LINE")

    return 0
}

################################################################################
# Get human readable date of a file ($1) of specific version (hash in $2)
################################################################################
function getFileReadableDate() {
    local FILE="$1"
    local HASH="$2"

    if getFileDate "${FILE}" "${HASH}" FILE_DATE ; then
        timestampToDate "${FILE_DATE}"
    else
        echo "${COL_YELLOW}Unknown version${COL_RESET}"
    fi
}

################################################################################
# Check if file ($1) is already up to date by comparing current file hash ($2),
# and hash of latest version of the file ($3)
# If so, print a message with date (timestamp in $4) of latest version
################################################################################
function isFileUpToDate() {
    local FILE="$1"
    local HASH="$2"
    local LATEST_HASH="$3"
    local LATEST_DATE_READABLE="$(timestampToDate "$4")"

    if [ "${LATEST_HASH}" == "${HASH}" ] ; then
        echo -e "File '${COL_GREEN}${FILE}${COL_RESET}' is already up to date (Version [${COL_YELLOW}${HASH:0:8}${COL_RESET}] from ${LATEST_DATE_READABLE})"
        return 0
    else
        return 1
    fi
}

################################################################################
# Prepare a commit message composed from file name ($1), current file hash ($2),
# hash ($3) and date (timestamp in $4) of latest version of the file 
################################################################################
function prepareAndPrintCommitMessage() {
    local FILE="$1"
    local HASH="$2"
    local LATEST_HASH_SHORT="${3:0:8}"
    local LATEST_DATE_READABLE="$(timestampToDate "$4")"

    # File exists in project, update
    if [ -n "${HASH}" ] ; then
        local FILE_DATE_READABLE="$(getFileReadableDate "${FILE}" "${HASH}")"
        MESSAGE="Updated file '${COL_GREEN}${FILE}${COL_RESET}' from version [${COL_YELLOW}${HASH:0:8}${COL_RESET}] (${FILE_DATE_READABLE}) to [${COL_YELLOW}${LATEST_HASH_SHORT}${COL_RESET}] (${LATEST_DATE_READABLE})"
    # New file
    else
        MESSAGE="Added new file '${COL_GREEN}${FILE}${COL_RESET}' with initial version [${COL_YELLOW}${LATEST_HASH_SHORT}${COL_RESET}] (${LATEST_DATE_READABLE})"
    fi

    # Display message
    echo -e "${MESSAGE}"
    
    # Prepare commit message
    [ -n "${OPT_COMMIT}" ] && [ ! -n "${OPT_DRY_RUN}" ] && addToCommitMessage "* $(filterColor "${MESSAGE}")"
}

################################################################################
# Copy the reference file ($1) to the project
################################################################################
function copyReferenceFileToProject() {
    local FILE_ID="$1"

    # Create directory first if it doesn't exists
    local BASE_DIR=$(dirname "${OPT_DIR_PROJECT}/${FILE_ID}")
    mkdir -p "${BASE_DIR}"

    # Copy the file
    cp "${DIR_ROOT_FS}/${FILE_ID}" "${OPT_DIR_PROJECT}/${FILE_ID}"
}

################################################################################
# Restore templated file ($1)
################################################################################
function restoreTemplatedFile() {
    local FILE="$1"

    # Insert template line and remove instanciated one
    sedInplace -e "s/^\(.*${TAG_TEMPLATE}:\(.*\)\)$/\1\n\2/" -e "/${TAG_TEMPLATE}/{n;d;}" "${FILE}"
}

################################################################################
# Instanciate templated file ($1)
################################################################################
function affectTemplateVariableInFile() {
    local FILE="$1"
    local VAR_NAME="$2"
    local VAR_VALUE="$3"

    # Insert template line and remove particularized one
    sedInplace -e "/${TAG_TEMPLATE}/n" -e "s#\[<${VAR_NAME}>\]#${VAR_VALUE}#" "${FILE}"
}
