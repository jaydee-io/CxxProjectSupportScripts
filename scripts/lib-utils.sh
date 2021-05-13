################################################################################
##                           CxxProjectSupportScripts
##
## This file is distributed under the 3-clause Berkeley Software Distribution
## License. See LICENSE for details.
################################################################################

################################################################################
# Globals
################################################################################
GITHUB_USER=""
GITHUB_PROJECT=""

################################################################################
# Portable version of sed inline replacement
################################################################################
function sedInplace() {
    case $(sed --help 2>&1) in
        *GNU*) sed -i "$@"    ;;
        *)     sed -i '' "$@" ;;
    esac
}

################################################################################
# Print arguments filtered from any color
################################################################################
function filterColor() {
    echo -e "$@" | sed $'s/\033\\[[^m]*m//g'
}

################################################################################
# Check if a regular expression ($1) match a least one value from an array
# (array name in $2)
################################################################################
function isInList() {
    local INDEX=$(getIndexInList "$1" "$2")

    [ -n "${INDEX}" ] && return 0 || return 1
}

################################################################################
# Print the index of the first value from an array (array name in $2),
# matching the regular expression ($1) 
################################################################################
function getIndexInList() {
    local EXPR="$1"
    local LIST_NAME="$2"
    eval local LIST_VALUES=\( \${${LIST_NAME}[@]} \)

    for I in "${!LIST_VALUES[@]}" ; do
        local VAL="${LIST_VALUES[$I]}"
        if [[ "$VAL" =~ ^${EXPR}$ ]] ; then
            echo $I
            return
        fi
    done
}

################################################################################
# Check that items in array (array name in $1) are not empty and that each item
# is in the spécified list (list name in $2), otherwise exit with an error
# message ($3).
################################################################################
function checkIsInList() {
    local PARAMS_NAME="$1"
    local LIST_NAME="$2"
    local LIST_NAME_DESCRIPTION="$3"
    eval local PARAMS=\( \${${PARAMS_NAME}[@]} \)

    [ ${#PARAMS[@]} -le 0 ] && usage 1 "You must provide at least one item"

    for PARAM in "${PARAMS[@]}" ; do
        ! isInList "${PARAM}" ${LIST_NAME} && usage 1 "'${PARAM}' is not in ${LIST_NAME_DESCRIPTION} list"
    done
}

################################################################################
# Return the size of the biggest string in the array's values (array name in $2)
################################################################################
function maxSize() {
    local MAX_SIZE=0
    local LIST_NAME="$1"
    eval local LIST_VALUES=\( \"\${${LIST_NAME}[@]}\" \)

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
# Insert a line of text ($3) in file ($1) at line ($2)
################################################################################
function insertLineAt() {
    local FILE="$1"
    local LINE="$2"
    local TEXT="$3"

    sedInplace -e "${LINE}i\\
${TEXT}
" "${FILE}"
}

################################################################################
# Find all lines matching expression ($1) in file ($2) and print line numbers
################################################################################
function findAllLineNumbersMatching() {
    local REGEXP="$1"
    local FILE="$2"

    grep -n -e "${REGEXP}" "${FILE}" | cut -d ":" -f 1
}

################################################################################
# Find first line matching expression ($1) in file ($2) and print line number
################################################################################
function findFirstLineNumberMatching() {
    local REGEXP="$1"
    local FILE="$2"

    findAllLineNumbersMatching "${REGEXP}" "${FILE}" | head -n 1
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

################################################################################
# Get Github user and project names from project repository ($1)
################################################################################
function getGithubUserAndProject() {
    local DIR_GIT_REPO="$1"
    local GITHUB_REMOTE=$(git -C "${DIR_GIT_REPO}" remote -v | grep "github.com" | head -n 1 | sed "s#.*git@github\.com:\(.*\)/\(.*\).git.*#\1 \2#")

    GITHUB_USER=$(cut -d " " -f 1 <<< "${GITHUB_REMOTE}")
    GITHUB_PROJECT=$(cut -d " " -f 2 <<< "${GITHUB_REMOTE}")
}

################################################################################
# Print human readable date from timestamp ($1)
################################################################################
function timestampToDate() {
    date -j -f %s "$1" +%d/%m/%Y
}