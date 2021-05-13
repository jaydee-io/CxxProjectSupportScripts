################################################################################
##                           CxxProjectSupportScripts
##
## This file is distributed under the 3-clause Berkeley Software Distribution
## License. See LICENSE for details.
################################################################################
source "${DIR_LIBS}/lib-file-versioning.sh"
source "${DIR_LIBS}/lib-badges.sh"
source "${DIR_LIBS}/lib-utils.sh"

################################################################################
# Print all available commands
################################################################################
function commandList() {
    # Commands
    local MAX_SIZE=$(maxSize ALL_COMMANDS)
    echo -e "Available commands:"
    for I in "${!ALL_COMMANDS[@]}" ; do
        printf "      ${COL_YELLOW}%-${MAX_SIZE}s${COL_RESET}   %s\n" "${ALL_COMMANDS[${I}]}" "${ALL_COMMANDS_DESCRIPTION[${I}]}"
    done
    
    # Command items
    local MAX_SIZE=$(maxSize ALL_ITEMS)
    echo
    echo -e "Available items (${COL_UNDERLINE}C${COL_RESET}reate / ${COL_UNDERLINE}U${COL_RESET}pdate / ${COL_UNDERLINE}A${COL_RESET}dd / ${COL_UNDERLINE}R${COL_RESET}emove):"
    for I in "${!ALL_ITEMS[@]}" ; do
        local ITEM="${ALL_ITEMS[${I}]}"

        isInList "${ITEM}" ALL_CREATE_ITEMS && printf "C" || printf " "
        isInList "${ITEM}" ALL_UPDATE_ITEMS && printf "U" || printf " "
        isInList "${ITEM}" ALL_ADD_ITEMS    && printf "A" || printf " "
        isInList "${ITEM}" ALL_REMOVE_ITEMS && printf "R" || printf " "
        printf "  ${COL_YELLOW}%-${MAX_SIZE}s${COL_RESET}   %s\n" "${ITEM}" "${ALL_ITEMS_DESCRIPTION[${I}]}"
    done

    # Badges
    local MAX_SIZE_BADGE=$(maxSize ALL_BADGES)
    local MAX_SIZE_BADGE_DESC=$(maxSize ALL_BADGES_ALT_TEXT)
    echo
    echo -e "Available badges:"
    for I in "${!ALL_BADGES[@]}" ; do
        printf "      ${COL_YELLOW}%-${MAX_SIZE_BADGE}s${COL_RESET}   %-${MAX_SIZE_BADGE_DESC}s   (%s)\n" "${ALL_BADGES[${I}]}" "${ALL_BADGES_ALT_TEXT[${I}]}" "${ALL_BADGES_LINK[${I}]}"
    done
}

################################################################################
# Update an item
################################################################################
function commandUpdate() {
    local PARAMS=("$@")
    
    checkIsInList PARAMS ALL_UPDATE_ITEMS "updatable items"

    for PARAM in "${PARAMS[@]}" ; do
        case "${PARAM}" in
            cmake-unittest)
                updateProjectFile "cmake/UnitTest.cmake"
                ;;
            cmake-code-coverage)
                updateProjectFile "cmake/CodeCoverage.cmake"
                updateProjectFile "codecov.yml"
                updateProjectFile "scripts/uploadCoverage.sh"
                ;;
        esac
    done
}

################################################################################
# Add an item
################################################################################
function commandAdd() {
    local ITEM="$1"
    shift 1
    local PARAMS=("$@")
    
    checkIsInList ITEM ALL_ADD_ITEMS "addable items"

    case "${ITEM}" in
        readme-badge)
            getGithubUserAndProject "${OPT_DIR_PROJECT}"
            setBadgesFile "${OPT_DIR_PROJECT}/README.md"
            getBadgeTagsLines || addBadgeTags 3
            
            for BADGE in "${PARAMS[@]}" ; do
                checkIsInList BADGE ALL_BADGES "badges"
                addBadge "${BADGE}"
            done

            # Commit file
            [ -n "${OPT_COMMIT}" ] && [ ! -n "${OPT_DRY_RUN}" ] && addFileTocommit "${OPT_DIR_PROJECT}" "README.md"
        ;;
    esac
}