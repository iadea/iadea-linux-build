#!/bin/bash

set -e
source "$(dirname $(realpath -e "${BASH_SOURCE[0]}"))/envsetup.sh"
cd "${PROJECT_ROOT}"

rm -rf "${TARGET_ROCKDEV}"

#
# extract base image
#

if [ ! -f "${BUILDSPEC_BASE_IMAGE}" ] ; then
    echo "missing base image '${BUILDSPEC_BASE_IMAGE}'"
    exit 1
fi

mkdir -p "${TARGET_ROCKDEV}"

"${RKIMAGEMAKER}" -unpack "${BUILDSPEC_BASE_IMAGE}" "${TARGET_ROCKDEV}"
rm "${TARGET_ROCKDEV}/boot.bin"

"${AFPTOOL}" -unpack "${TARGET_ROCKDEV}/firmware.img" "${TARGET_ROCKDEV}"
rm "${TARGET_ROCKDEV}/firmware.img"

if [ -d "${TARGET_ROCKDEV}/Image" ] ; then
    mv "${TARGET_ROCKDEV}/Image"/* "${TARGET_ROCKDEV}"/
    rm -rf "${TARGET_ROCKDEV}/Image"
fi

#
# replace images
#

count=0

if [ -f "${TARGET_BOOT_IMAGE}" ] ; then
    ln -fs -T "${TARGET_BOOT_IMAGE}" "${TARGET_ROCKDEV}/boot.img"
    count=$((count + 1))
else
    echo 'WARNING: keep original boot image'
fi

if [ -f "${TARGET_SYSTEM_IMAGE}" ] ; then
    ln -fs -T "${TARGET_SYSTEM_IMAGE}" "${TARGET_ROCKDEV}/system.bin"
    count=$((count + 1))
else
    echo 'WARNING: keep original system image'
fi

if [ -f "${TARGET_OEM_IMAGE}" ] ; then
    ln -fs -T "${TARGET_OEM_IMAGE}" "${TARGET_ROCKDEV}/oem.img"
    count=$((count + 1))
else
    echo 'WARNING: keep original oem image'
fi

if (( count == 0 )) ; then
    echo 'there are no images to update'
    exit 1
fi

#
# build production image
#

VARIANT="$(sed -ne 's/^MACHINE:[[:space:]]*\(.*\)[[:space:]]*$/\1/;T;s|/|-|g;p;q' "${TARGET_ROCKDEV}/parameter.txt")"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

TARGET_PROD_IMAGE="${PROJECT_OUT}/prod-${VARIANT:-unknown}-linux-migration-${TIMESTAMP}.img"

"${AFPTOOL}" -pack "${TARGET_ROCKDEV}" "${TARGET_ROCKDEV}/firmware.img"
"${RKIMAGEMAKER}" -RK32 "${TARGET_ROCKDEV}/loader.bin" "${TARGET_ROCKDEV}/firmware.img" "${TARGET_PROD_IMAGE}" -os_type:androidos

echo "created production image: ${TARGET_PROD_IMAGE}"
