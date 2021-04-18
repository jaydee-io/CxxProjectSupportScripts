################################################################################
##                           CxxProjectSupportScripts
##
## This file is distributed under the 3-clause Berkeley Software Distribution
## License. See LICENSE for details.
################################################################################

################################################################################
# Directories constants
################################################################################
export DIR_BASE=$(dirname "$0")
export DIR_LIBS="${DIR_BASE}/scripts"
export DIR_ROOT_FS_SHORT="root"
export DIR_ROOT_FS="${DIR_BASE}/${DIR_ROOT_FS_SHORT}"

################################################################################
# File name constants
################################################################################
export FILE_VERSIONS="${DIR_BASE}/VERSIONS"
export FILE_COMMIT_MSG="$(realpath "${DIR_BASE}/COMMIT_MSG.txt")"

################################################################################
# Binary constants
################################################################################
export BIN_CHECKSUM="sha1sum"

################################################################################
# Color constants
################################################################################
export COL_RED="\033[31m"
export COL_GREEN="\033[32m"
export COL_YELLOW="\033[33m"

export COL_RESET="\033[0m"
export COL_BOLD="\033[1m"
export COL_UNDERLINE="\033[4m"

################################################################################
# Some globals
################################################################################
ALL_COMMANDS=(
    "list"
    "create"
    "update"
    "add"
    "remove"
)

ALL_COMMANDS_DESCRIPTION=(
    "List all available commands"
    "Create a project's item (Accept multiple items and regex)"
    "Update a project's item (Accept multiple items and regex)"
    "Add a project's item (Need arguments)"
    "Remove a project's item (Need arguments)"
)

ALL_ITEMS=(
    "cmake-unittest"
    "readme-badge"
)

ALL_ITEMS_DESCRIPTION=(
    "CMake file providing unit-testing"
    "Badges (Licence, version, build status, ...) on README.md (see http://shield.io)"
)

ALL_CREATE_ITEMS=(
    "cmake-unittest"
)
ALL_UPDATE_ITEMS=(
    "cmake-unittest"
)
ALL_ADD_ITEMS=(
    "readme-badge"
)
ALL_REMOVE_ITEMS=(
    "readme-badge"
)