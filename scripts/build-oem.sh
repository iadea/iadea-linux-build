#!/bin/bash

set -e
source "$(dirname $(readlink -e "${BASH_SOURCE[0]}"))/envsetup.sh"
cd "${PROJECT_ROOT}"

rm -rf "${TARGET_OEM_IMAGE}"

#
# build oem image
#

if [ ! -d "${BUILDSPEC_OEM}" ] ; then
    echo "oem path '${BUILDSPEC_OEM}' does not exist"
    exit 1
fi

cmd=( mksquashfs "$(readlink -e "${BUILDSPEC_OEM}")" "${TARGET_OEM_IMAGE}" -noappend -all-root )

"${cmd[@]}" -comp 'lz4' -Xhc ||
"${cmd[@]}" -comp 'gzip' -Xcompression-level 9
