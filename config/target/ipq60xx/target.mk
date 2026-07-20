SUBTARGET:=ipq60xx
FEATURES += source-only
BOARDNAME:=Qualcomm Atheros IPQ60xx
DEFAULT_PACKAGES += kmod-usb3 kmod-usb-phy-msm

define Target/Description
	Build firmware images for Qualcomm Atheros IPQ60xx based boards.
endef
