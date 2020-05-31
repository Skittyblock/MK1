TARGET = iphone:clang::11.0
ARCHS = arm64 arm64e

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ZZZMK1XenHTML

ZZZMK1XenHTML_FILES = Tweak.x
ZZZMK1XenHTML_CFLAGS = -fobjc-arc
ZZZMK1XenHTML_LIBRARIES = rocketbootstrap
ZZZMK1XenHTML_FRAMEWORKS = WebKit
ZZZMK1XenHTML_PRIVATE_FRAMEWORKS = AppSupport

include $(THEOS_MAKE_PATH)/tweak.mk
