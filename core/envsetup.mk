LOCAL_VARIABLES := $(.VARIABLES)

PROJECT_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/../../..)

include $(PROJECT_ROOT)/buildspec.mk

RESOURCE_TOOL := $(PROJECT_ROOT)/kernel/scripts/resource_tool
MKBOOTIMG := $(PROJECT_ROOT)/iadea/build/tools/mkbootimg
AFPTOOL := $(PROJECT_ROOT)/tools/linux/Linux_Pack_Firmware/rockdev/afptool
RKIMAGEMAKER :=$(PROJECT_ROOT)/tools/linux/Linux_Pack_Firmware/rockdev/rkImageMaker

PROJECT_OUT := $(PROJECT_ROOT)/out/$(BUILDSPEC_PRODUCT)

TARGET_BOOT_RESOURCE := $(PROJECT_OUT)/boot-resource.img
TARGET_KERNEL_MODULES := $(PROJECT_OUT)/installed-kernel-modules
TARGET_ROOTFS := $(PROJECT_OUT)/rootfs
TARGET_ROCKDEV :=$(PROJECT_OUT)/rockdev

TARGET_BOOT_IMAGE := $(PROJECT_OUT)/linux-boot.img
TARGET_SYSTEM_IMAGE := $(PROJECT_OUT)/linux-system.img
TARGET_OEM_IMAGE := $(PROJECT_OUT)/linux-oem.img

LOCAL_VARIABLES := $(filter-out $(LOCAL_VARIABLES) LOCAL_VARIABLES, $(.VARIABLES))

ifneq ($(filter export-variables,$(MAKECMDGOALS)),)

$(foreach VARIABLE, $(LOCAL_VARIABLES), $(info $(VARIABLE)='$($(VARIABLE))'))

.PHONY: export-variables
export-variables:
	@true

endif
