################################################################################
##                           CxxProjectSupportScripts
##
## This file is distributed under the 3-clause Berkeley Software Distribution
## License. See LICENSE for details.
################################################################################

################################################################################
# Globals
################################################################################
TAG_BADGES_BEGIN="BEGIN BADGES"
TAG_BADGES_END="END   BADGES"
BASE_URL_SHIELD="https://img.shields.io"
BADGE_FILE=""
LINE_INSERT_BADGE="0"
GITHUB_USER=""
GITHUB_PROJECT=""

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
# Set file ($1) to insert badge into
################################################################################
function setBadgesFile() {
    BADGE_FILE="$1"
}

################################################################################
# Get badge tag line numbers in badge file, if present (otherwise return 1)
################################################################################
function getBadgeTagsLines() {
    local LINE_BEGIN=$(grep -n -e "${TAG_BADGES_BEGIN}" "${BADGE_FILE}" | head -n 1 | cut -d ":" -f 1)
    local LINE_END=$(  grep -n -e "${TAG_BADGES_END}"   "${BADGE_FILE}" | head -n 1 | cut -d ":" -f 1)

    ([ -z "${LINE_BEGIN}" ] || [ -z "${LINE_END}" ]) && return 1

    LINE_INSERT_BADGE=$((${LINE_END} - 1))
    return 0
}

################################################################################
# Add badge tags to badge file at line ($1)
################################################################################
function addBadgeTags() {
    local LINE="$1"

    insertLineAt "${BADGE_FILE}" $((${LINE} + 0)) "<!-- ${TAG_BADGES_BEGIN} -->"
    insertLineAt "${BADGE_FILE}" $((${LINE} + 1)) "<!-- ${TAG_BADGES_END} -->"

    LINE_INSERT_BADGE=$((${LINE} + 1))
}

################################################################################
# Add badge ($1) to badge file
################################################################################
function addBadge() {
    local BADGE="$1"
    local BADGE_IDX=$(getIndexInList "${BADGE}" ALL_BADGES)
    local BADGE_ALT_TEXT=$(eval echo \"${ALL_BADGES_ALT_TEXT[${BADGE_IDX}]}\")
    local BADGE_ICON=$(eval echo \"${ALL_BADGES_ICON[${BADGE_IDX}]}\")
    local BADGE_LINK=$(eval echo \"${ALL_BADGES_LINK[${BADGE_IDX}]}\")

    # Display and prepare commit message
    MESSAGE="Add badge '${COL_GREEN}${BADGE_ALT_TEXT}${COL_RESET}' to '${COL_YELLOW}${BADGE_FILE}${COL_RESET}'"
    echo -e "${MESSAGE}"
    [ -n "${OPT_COMMIT}" ] && addToCommitMessage "* $(echo -e "${MESSAGE}" | sed $'s/\033\\[[^m]*m//g')"

    # Insert badge
    [ ! -n "${OPT_DRY_RUN}" ] && insertLineAt "${BADGE_FILE}" "${LINE_INSERT_BADGE}" "[![${BADGE_ALT_TEXT}](${BASE_URL_SHIELD}${BADGE_ICON})](${BADGE_LINK})"

    LINE_INSERT_BADGE=$((${LINE_INSERT_BADGE} + 1))
}
