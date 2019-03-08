#!/bin/bash

set -e
source "$(dirname $(readlink -e "${BASH_SOURCE[0]}"))/envsetup.sh"
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
# replace parameters
#

mv "${TARGET_ROCKDEV}/parameter.txt" "${TARGET_ROCKDEV}/parameter.txt-orig"

if [ "${BUILDSPEC_SYSTEM_PARTITION_SIZE}" ] ; then
    mtdparts="$(
        sed -ne 's/^CMDLINE:.*mtdparts=rk29xxnand:\([^ ]*\).*$/\1/;T;s/\([^@]*\)@\([^(]*\)(\([^)]*\))\(,\|$\)/\1 \2 \3\n/g;p;q' \
            "${TARGET_ROCKDEV}/parameter.txt-orig" |
        awk -Wposix -v "system_partition_size=${BUILDSPEC_SYSTEM_PARTITION_SIZE}" '
            BEGIN {
                count = 0;
                shift = 0;
            }
            NF == 3 {
                $2 = sprintf("0x%08X", $2 + shift);
                if ($1 != "-") {
                    if ($3 == "system") {
                        shift += system_partition_size / 512 - $1;
                        $1 = system_partition_size / 512 ;
                    }
                    $1 = sprintf("0x%08X", $1);
                }
                if (0 == count++) {
                    printf("rk29xxnand:");
                }
                else {
                    printf(",");
                }
                printf("%s@%s(%s)", $1, $2, $3);
            }'
    )"
else
    mtdparts='\2'
fi

#TODO: add
#    -e '/^\(TYPE:\|uuid:\)/d'
#    -e '$a\TYPE: GPT\nuuid:system=614e0000-0000-4b53-8000-1d28000054a9'

sed -e "s/^\\(CMDLINE:.*mtdparts=\\)\\([^ ]*\\)/\\1${mtdparts}/" \
    "${TARGET_ROCKDEV}/parameter.txt-orig" > "${TARGET_ROCKDEV}/parameter.txt"

#
# build production image
#

VARIANT="$(sed -ne 's/^MACHINE:[[:space:]]*\(.*\)[[:space:]]*$/\1/;T;s|/|-|g;p;q' "${TARGET_ROCKDEV}/parameter.txt")"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

TARGET_PROD_IMAGE="${PROJECT_OUT}/prod-${VARIANT:-unknown}-linux-migration-${TIMESTAMP}.img"

"${AFPTOOL}" -pack "${TARGET_ROCKDEV}" "${TARGET_ROCKDEV}/firmware.img"
"${RKIMAGEMAKER}" -RK32 "${TARGET_ROCKDEV}/loader.bin" "${TARGET_ROCKDEV}/firmware.img" "${TARGET_PROD_IMAGE}" -os_type:androidos

echo "created production image: ${TARGET_PROD_IMAGE}"
