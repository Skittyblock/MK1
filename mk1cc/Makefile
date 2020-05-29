include $(THEOS)/makefiles/common.mk

export TARGET = iphone:clang:13.0:11.0
export ARCHS = arm64 arm64e

BUNDLE_NAME = mk1cc
mk1cc_BUNDLE_EXTENSION = bundle
mk1cc_FILES = mk1cc.m
mk1cc_LIBRARIES = rocketbootstrap
mk1cc_PRIVATE_FRAMEWORKS = ControlCenterUIKit AppSupport
mk1cc_INSTALL_PATH = /Library/ControlCenter/Bundles/

after-install::
	install.exec "killall -9 SpringBoard"

include $(THEOS_MAKE_PATH)/bundle.mk
