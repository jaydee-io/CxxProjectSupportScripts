#!/bin/bash
################################################################################
##                           CxxProjectSupportScripts
##
## This file is distributed under the 3-clause Berkeley Software Distribution
## License. See LICENSE for details.
################################################################################
source "$(dirname "$0")/scripts/lib-global-constants.sh"
source "${DIR_LIBS}/lib-utils.sh"
source "${DIR_LIBS}/lib-command-line-parsing.sh"
source "${DIR_LIBS}/lib-commands.sh"

################################################################################
# Parse command line and check arguments
################################################################################
parseCommandLineOptions "$@"
checkArguments

################################################################################
# Prepare commit message
################################################################################
[ -n "${OPT_COMMIT}" ] && [ ! -f "${FILE_COMMIT_MSG}" ] && addToCommitMessage "Updated configuration files\n\nList of changes:"

################################################################################
# Process command
################################################################################
COMMAND="${OPT_COMMANDS[0]}"
unset OPT_COMMANDS[0]
case "$COMMAND" in
    "list")   commandList   "${OPT_COMMANDS[@]}" ;;
    "update") commandUpdate "${OPT_COMMANDS[@]}" ;;
    "add")    commandAdd    "${OPT_COMMANDS[@]}" ;;
    *)        usage 1 "Unknown command '${COMMAND}'" ;;
esac

################################################################################
# Commit
################################################################################
if [ -n "${OPT_COMMIT}" ] && [ ! -n "${OPT_DRY_RUN}" ] ; then
    commitChanges "${OPT_DIR_PROJECT}"
    removeCommitMessageFile
fi
