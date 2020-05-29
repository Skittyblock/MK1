TARGET = iphone:clang:13.0:13.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = MK1

MK1_FILES = main.m MKAppDelegate.m MKRootViewController.m MKConsoleViewController.m MKScriptsViewController.m MKScript.m
MK1_LIBRARIES = rocketbootstrap
MK1_PRIVATE_FRAMEWORKS = AppSupport
MK1_FRAMEWORKS = UIKit CoreGraphics
MK1_CFLAGS = -fobjc-arc -Wno-error=deprecated-declarations

include $(THEOS_MAKE_PATH)/application.mk

after-install::
	install.exec "killall \"MK1\"" || true
