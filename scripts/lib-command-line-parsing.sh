################################################################################
##                           CxxProjectSupportScripts
##
## This file is distributed under the 3-clause Berkeley Software Distribution
## License. See LICENSE for details.
################################################################################

################################################################################
# Print error message, usage and exit with status code if specified
################################################################################
function usage() {
    local ERROR_CODE="$1"
    local ERROR_MESSAGE="$2"

    [ -n "$ERROR_MESSAGE" ] && echo -e "Error: ${COL_RED}${ERROR_MESSAGE}${COL_RESET}\n"


    echo -e "${COL_BOLD}Usage${COL_RESET}: $0 <OPTIONS> <COMMAND> [<COMMAND PARAMS>...]"
    echo -e ""
    echo -e "${COL_BOLD}OPTIONS${COL_RESET}:"
    echo -e "    -p,--project <project> : Directory of the project to update"
    echo -e "    -c,--commit            : Commit the updated project files"
    echo -e "    -f,--force             : Overwrite a file, even if has been localy modified"
    echo -e "    -n,--dry-run           : Do not update files, but show what should be done"
    echo -e "    -h,--help              : Print usage help"
    echo -e ""
    echo -e "${COL_UNDERLINE}Project option is mandatory${COL_RESET}"
    echo -e ""
    echo -e "${COL_BOLD}COMMAND${COL_RESET}:"

    local MAX_SIZE=$(maxSize ALL_COMMANDS)
    for I in "${!ALL_COMMANDS[@]}" ; do
        printf "    ${COL_YELLOW}%-$(($MAX_SIZE + 3))s${COL_RESET}%s\n" "${ALL_COMMANDS[$I]}" "${ALL_COMMANDS_DESCRIPTION[$I]}"
    done

    if [ -n "$ERROR_CODE" ] && [ $ERROR_CODE -gt -1 ] 2> /dev/null ; then
        exit $ERROR_CODE
    fi
}

################################################################################
# Parse command line arguments
################################################################################
function parseCommandLineOptions() {
    while [ $# -gt 0 ] ; do
        case $1 in
            -p|--project) OPT_DIR_PROJECT="$2"; shift 1 ;;
            -c|--commit)  OPT_COMMIT="yes" ;;
            -f|--force)   OPT_FORCE="yes" ;;
            -n|--dry-run) OPT_DRY_RUN="yes" ;;
            -h|--help)    usage 0 ;;
            -*)           usage 1 "Unkown option '$1'" ;;
            *)            OPT_COMMANDS+=("$1") ;;
        esac

        shift 1
    done
}

function checkArguments () {
    [   -z "$OPT_DIR_PROJECT" ]       && usage 1 "Missing project directory (with -p, --project option)"
    [ ! -d "$OPT_DIR_PROJECT" ]       && usage 1 "Project argument is not a directory '$OPT_DIR_PROJECT'"

    [ ${#OPT_COMMANDS[*]} -eq 0 ] && usage 1 "Missing command"
}