include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = MK1CC
MK1CC_BUNDLE_EXTENSION = bundle
MK1CC_FILES = MKCCToggleModule.m
MK1CC_LIBRARIES = rocketbootstrap
MK1CC_PRIVATE_FRAMEWORKS = ControlCenterUIKit AppSupport
MK1CC_INSTALL_PATH = /Library/ControlCenter/Bundles/

after-install::
	install.exec "killall -9 SpringBoard"

include $(THEOS_MAKE_PATH)/bundle.mk
