#!/bin/bash

PROJECT_ROOT="$(dirname $(readlink -e "${BASH_SOURCE[0]}") | sed -ne 's|/iadea/build/scripts$||p')"

if [ -z "${PROJECT_ROOT}" ] ; then
    echo "canonical script path must end with /iadea/build/scripts"
    exit 1
fi

eval "$(make -s -f "${PROJECT_ROOT}/iadea/build/core/envsetup.mk" export-variables)"

if [ "${PROJECT_OUT}" ] ; then
    mkdir -p "${PROJECT_OUT}" || exit
fi
