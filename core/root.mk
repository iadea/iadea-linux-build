KERNEL_TARGETS := kernel-modules boot-image
ROOTFS_TARGETS := system-image
OEM_TARGETS := oem-image
PROD_IMAGE_TARGETS := prod-image rockdev

.PHONY: help
.DEFAULT: help
help:
	@echo
	@echo 'kernel targets:'
	@echo '    build-kernel $(KERNEL_TARGETS)'
	@echo
	@echo 'rootfs targets:'
	@echo '    build-rootfs $(ROOTFS_TARGETS)'
	@echo
	@echo 'oem targets:'
	@echo '    build-oem $(OEM_TARGETS)'
	@echo
	@echo 'prod-image targets:'
	@echo '    build-prod-image $(PROD_IMAGE_TARGETS)'
	@echo

include iadea/build/core/envsetup.mk

.PHONY: $(KERNEL_TARGETS) build-kernel
.PHONY: $(ROOTFS_TARGETS) build-rootfs
.PHONY: $(OEM_TARGETS) build-oem
.PHONY: $(PROD_IMAGE_TARGETS) build-prod-image

$(KERNEL_TARGETS): build-kernel
$(ROOTFS_TARGETS): build-rootfs
$(OEM_TARGETS): build-oem
$(PROD_IMAGE_TARGETS): build-prod-image

build-rootfs: build-kernel
build-prod-image: build-kernel build-rootfs build-oem

build-kernel build-rootfs build-oem build-prod-image:
	@$(PROJECT_ROOT)/iadea/build/scripts/$@.sh
