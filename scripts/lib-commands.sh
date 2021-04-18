################################################################################
##                           CxxProjectSupportScripts
##
## This file is distributed under the 3-clause Berkeley Software Distribution
## License. See LICENSE for details.
################################################################################

################################################################################
# Print all available commands
################################################################################
function commandList() {
    echo -e "Available commands:"
    local MAX_SIZE=$(maxSize ALL_COMMANDS)
    for I in "${!ALL_COMMANDS[@]}" ; do
        printf "    ${COL_YELLOW}%-$(($MAX_SIZE + 3))s${COL_RESET}%s\n" "${ALL_COMMANDS[${I}]}" "${ALL_COMMANDS_DESCRIPTION[${I}]}"
    done
    echo
    echo -e "Available items (${COL_UNDERLINE}C${COL_RESET}reate / ${COL_UNDERLINE}U${COL_RESET}pdate / ${COL_UNDERLINE}A${COL_RESET}dd / ${COL_UNDERLINE}R${COL_RESET}emove):"
    local MAX_SIZE=$(maxSize ALL_ITEMS)
    for I in "${!ALL_ITEMS[@]}" ; do
        local ITEM="${ALL_ITEMS[${I}]}"

        isInList "${ITEM}" ALL_CREATE_ITEMS && printf "C" || printf " "
        isInList "${ITEM}" ALL_UPDATE_ITEMS && printf "U" || printf " "
        isInList "${ITEM}" ALL_ADD_ITEMS    && printf "A" || printf " "
        isInList "${ITEM}" ALL_REMOVE_ITEMS && printf "R" || printf " "
        printf "    ${COL_YELLOW}%-$(($MAX_SIZE + 3))s${COL_RESET}%s\n" "${ITEM}" "${ALL_ITEMS_DESCRIPTION[${I}]}"
    done
}

################################################################################
# Update an item
################################################################################
function commandUpdate() {
    local PARAMS=("$@")
    
    checkItems PARAMS ALL_UPDATE_ITEMS "an updatable item"

    for PARAM in "${PARAMS[@]}" ; do
        case "${PARAM}" in
            cmake-unittest) updateProjectFile "cmake/UnitTest.cmake" ;;
        esac
    done
}