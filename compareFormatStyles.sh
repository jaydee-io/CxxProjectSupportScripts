#!/bin/bash

DIR_TO_FORMAT="${1:-.}"

ALL_STYLES=(LLVM Google Chromium Mozilla WebKit Microsoft GNU)

for STYLE in "${ALL_STYLES[@]}" ; do
    printf "################################################### %-10s ###################################################\n" "${STYLE}"
    clang-format --dump-config --style="${STYLE}" > .clang-format

    for FILE in $(find ${DIR_TO_FORMAT} -iname "*.cpp" -or -iname "*.h") ; do
        printf "*************************************************** %10s ***************************************************\n" "${FILE}"
        clang-format --style=file -i "${FILE}"
    done

    git --no-pager diff --stat | tee ${STYLE}_diff_stats.txt
    git restore "${DIR_TO_FORMAT}"
done


for STYLE in "${ALL_STYLES[@]}" ; do
    printf "%-10s " "${STYLE}"
    tail -n 1 ${STYLE}_diff_stats.txt
done