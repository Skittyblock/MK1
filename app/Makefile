include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = MK1
MK1_FILES = $(wildcard *.m)
MK1_LIBRARIES = rocketbootstrap
MK1_PRIVATE_FRAMEWORKS = AppSupport
MK1_FRAMEWORKS = UIKit CoreGraphics
MK1_CFLAGS = -fobjc-arc -Wno-error=deprecated-declarations

include $(THEOS_MAKE_PATH)/application.mk

after-install::
	install.exec "killall \"MK1\"" || true
