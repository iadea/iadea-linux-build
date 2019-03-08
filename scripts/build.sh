#!/bin/bash

set -e
source "$(dirname $(readlink -e "${BASH_SOURCE[0]}"))/envsetup.sh"
cd "${PROJECT_ROOT}"

for target in "$@" ; do
    case "${target}" in
    kernel|boot-image|boot-resource|kernel-modules)
        "${PROJECT_ROOT}"/iadea/build/scripts/build-kernel.sh
        ;;
    rootfs|system-image)
        "${PROJECT_ROOT}"/iadea/build/scripts/build-rootfs.sh
        ;;
    oem|oem-image)
        "${PROJECT_ROOT}"/iadea/build/scripts/build-oem.sh
        ;;
    prod-image|rockdev)
        "${PROJECT_ROOT}"/iadea/build/scripts/build-prod-image.sh
        ;;
    *)
        echo "WARNING: unknown target ${target}"
        ;;
    esac
done
