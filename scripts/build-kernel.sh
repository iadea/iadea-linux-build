#!/bin/bash

set -e
source "$(dirname $(readlink -e "${BASH_SOURCE[0]}"))/envsetup.sh"
cd "${PROJECT_ROOT}"

rm -rf "${TARGET_BOOT_IMAGE}" "${TARGET_BOOT_RESOURCE}" "${TARGET_KERNEL_MODULES}"

#
# patch kernel
#

if [ ! -f "iadea/kernel/configs/${BUILDSPEC_PRODUCT}_defconfig" ] ||
   [ ! -d "iadea/kernel/dts/${BUILDSPEC_PRODUCT}" ] ; then

    echo "product '${BUILDSPEC_PRODUCT}' is not supported"
    exit 1
fi

ln -fs -T "${PROJECT_ROOT}/iadea/kernel/configs" 'kernel/arch/arm/configs/iadea'
ln -fs -T "${PROJECT_ROOT}/iadea/kernel/dts/${BUILDSPEC_PRODUCT}" "kernel/arch/arm/boot/dts/iadea-${BUILDSPEC_PRODUCT}"

(
    cd kernel
    for patchfile in "${PROJECT_ROOT}/iadea/kernel/patches"/* ; do
        if ! patch --silent --force --reverse --dry-run -p1 <"${patchfile}" ; then
            patch -p1 <"${patchfile}"
        fi
    done
)

#
# configure kernel
#

make -C 'kernel' ARCH=arm "iadea/${BUILDSPEC_PRODUCT}_defconfig"


#
# build kernel images
#

make -C 'kernel' ARCH=arm -j4 zImage dtbs modules

#
# build boot image
#

(
    cd "kernel/arch/arm/boot/dts/iadea-${BUILDSPEC_PRODUCT}"
    touch '0.dtb'
    "${RESOURCE_TOOL}" --image="${TARGET_BOOT_RESOURCE}" *.dtb
)

"${MKBOOTIMG}" --kernel 'kernel/arch/arm/boot/zImage' --second "${TARGET_BOOT_RESOURCE}" -o "${TARGET_BOOT_IMAGE}"

#
# build kernel modules
#

mkdir -p "${TARGET_KERNEL_MODULES}"
make -C 'kernel' ARCH=arm INSTALL_MOD_PATH="${TARGET_KERNEL_MODULES}" modules_install
