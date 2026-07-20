define Device/zn_m2
	$(call Device/FitImage)
	$(call Device/UbiFit)
	BLOCKSIZE := 128k
	PAGESIZE := 2048
	DEVICE_DTS := ipq6018-zn-m2
	DEVICE_TITLE := ZN M2 (ethernet only)
	DEVICE_PACKAGES := kmod-usb3 kmod-usb-phy-msm
	ROOTFS_PARTSIZE := 20M
endef
TARGET_DEVICES += zn_m2
