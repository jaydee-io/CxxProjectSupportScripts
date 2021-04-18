################################################################################
##                           CxxProjectSupportScripts
##
## This file is distributed under the 3-clause Berkeley Software Distribution
## License. See LICENSE for details.
################################################################################

################################################################################
# Check if a regular expression ($1) match a least one value from an array
# (array name in $2)
################################################################################
function isInList() {
    local EXPR="$1"
    local LIST_NAME="$2"
    eval local LIST_VALUES=\( \${${LIST_NAME}[@]} \)

    for VAL in "${LIST_VALUES[@]}" ; do
        [[ "$VAL" =~ ^${EXPR}$ ]] && return 0
    done

    return 1
}

################################################################################
# Check that items in array (array name in $1) are not empty and that each item
# is in the spécified list (list name in $2), otherwise exit with an error
# message ($3).
################################################################################
function checkItems() {
    local PARAMS_NAME="$1"
    local LIST_NAME="$2"
    local ERROR_MSG="$3"
    eval local PARAMS=\( \${${PARAMS_NAME}[@]} \)

    [ ${#PARAMS[@]} -le 0 ] && usage 1 "You must provide at least one item"

    for PARAM in "${PARAMS[@]}" ; do
        ! isInList "${PARAM}" ${LIST_NAME} && usage 1 "'${PARAM}' is not ${ERROR_MSG}"
    done
}

################################################################################
# Return the size of the biggest string in the array's values (array name in $2)
################################################################################
function maxSize() {
    local MAX_SIZE=0
    local LIST_NAME="$1"
    eval local LIST_VALUES=\( \${${LIST_NAME}[@]} \)

    for I in "${!LIST_VALUES[@]}" ; do
        [ ${#LIST_VALUES[$I]} -gt ${MAX_SIZE} ] && MAX_SIZE=${#LIST_VALUES[$I]}
    done
    
    echo ${MAX_SIZE}
}

################################################################################
# Remove N ($2) characters from the left of the string ($1)
################################################################################
function trimLeft() {
    echo "${1:$2}"
}

################################################################################
# Append some text ($1) to the commit message
################################################################################
function addToCommitMessage() {
    local MSG="$1"
    
    echo -e "$MSG" >> "${FILE_COMMIT_MSG}"
}

################################################################################
# Add file ($1) to commit
################################################################################
function addFileTocommit() {
    local DIR_GIT_REPO="$1"
    local FILE="$2"
    
    git -C "${DIR_GIT_REPO}" add "${FILE}"
}

################################################################################
# Append some text ($1) to the commit message
################################################################################
function commitChanges() {
    local DIR_GIT_REPO="$1"
    
    git -C "${DIR_GIT_REPO}" commit --file "${FILE_COMMIT_MSG}"
}

################################################################################
# Remove commit message file
################################################################################
function removeCommitMessageFile() {
    rm -f "${FILE_COMMIT_MSG}"
}