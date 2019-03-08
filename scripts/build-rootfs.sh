#!/bin/bash

set -e
source "$(dirname $(readlink -e "${BASH_SOURCE[0]}"))/envsetup.sh"
cd "${PROJECT_ROOT}"

sudo rm -rf "${TARGET_SYSTEM_IMAGE}"

finish() {
    if [ -d "${__mount_point}" ] ; then
        sudo umount "${__mount_point}"
    fi
    exit 1
}

trap finish ERR

#
# check kernel modules
#

if [ ! -e "${TARGET_KERNEL_MODULES}" ] ; then
    echo "Missing kernel modules. Run build-kernel.sh first!"
    exit 1
fi

#
# build Debian base
#

if [ ! -e rootfs/linaro-stretch-alip-*.tar.gz ] ; then

    dpkg_status="$(
        dpkg-query -W -f '${Package} ${Version} ${db:Status-Status}\n' \
            binfmt-support qemu-user-static \
            $(find rootfs/ubuntu-build-service/packages/ -name "*.deb" -printf '%P\n' | cut -f1 -d_) \
            2>&1
        )"

    if [ "$(echo "${dpkg_status}" | sed '/ installed$/d')" ] ; then
        echo <<EOS
Ubuntu-build-service requires additional packages to install.

${dpkg_status}

You may try following commands

sudo apt-get install binfmt-support qemu-user-static
sudo dpkg -i -G -R rootfs/ubuntu-build-service/packages

See rootfs/readme.md for more details.
EOS
        exit 1
    fi

    (
        cd rootfs
        RELEASE='stretch' ARCH='armhf' TARGET='desktop' ./mk-base-debian.sh
    )

    sudo rm -rf 'rootfs/binary'

fi

#
# build Rockchip rootfs
#

if [ ! -e 'rootfs/binary' ] ; then

    (
        cd rootfs
        VERSION='debug' ARCH='armhf' ./mk-rootfs-stretch.sh
    )

fi

#
# build IAdea rootfs
#

ln -fs -T "${PROJECT_ROOT}/rootfs/binary" "${TARGET_ROOTFS}"

sudo cp -drf "${TARGET_KERNEL_MODULES}"/* "${TARGET_ROOTFS}/"
sudo cp -drf 'iadea/rootfs/overlay'/* "${TARGET_ROOTFS}/"

__mount_point="${TARGET_ROOTFS}/dev"
sudo mount -o bind /dev "${__mount_point}"

cat <<EOS | sudo chroot "${TARGET_ROOTFS}"

mkdir -p /data

if [ -e /usr/local/sbin/adbd -a ! -e /usr/local/bin/adbd ] ; then
    ln -fs ../sbin/adbd /usr/local/bin/adbd
fi

apt-get update
apt-get install -y util-linux modem-manager-gui ppp

true

EOS

sudo umount "${__mount_point}"
__mount_point=

#
# build system image
#

case "${BUILDSPEC_FSTYPE:-squashfs}" in
squashfs)
    cmd=( mksquashfs "$(readlink -e "${TARGET_ROOTFS}")" "${TARGET_SYSTEM_IMAGE}" -noappend -ef 'iadea/rootfs/exclusion-list' -wildcards )

    sudo "${cmd[@]}" -comp 'lz4' -Xhc ||
    sudo "${cmd[@]}" -comp 'gzip' -Xcompression-level 9
    ;;

ext4)
    dd if=/dev/zero of="${TARGET_SYSTEM_IMAGE}" bs=1M count=0 seek=2048
    mkfs.ext4 "${TARGET_SYSTEM_IMAGE}"

    __mount_point="${TARGET_ROOTFS}-mirror"
    mkdir -p "$__mount_point"
    sudo mount -t ext4 -o rw "${TARGET_SYSTEM_IMAGE}" "${__mount_point}"

    sudo rsync -ax --delete --exclude-from='iadea/rootfs/exclusion-list' "${TARGET_ROOTFS}"/ "${__mount_point}"/

    sudo umount "${__mount_point}"
    __mount_point=

    fsck.ext4 -f -p "${TARGET_SYSTEM_IMAGE}" || [ "$?" -lt 4 ]
    resize2fs -M "${TARGET_SYSTEM_IMAGE}"
    ;;

*)
    echo "file system type '${BUILDSPEC_FSTYPE}' is not supported"
    exit 1
    ;;
esac
