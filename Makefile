TARGET = iphone:clang:13.0:11.0
INSTALL_TARGET_PROCESSES = SpringBoard
ARCHS = arm64 arm64e

VERSION = "9.9.9" # used to display version via MK1.version
GIT_HASH = `git rev-parse HEAD`
export VERSION_FLAGS=-DMK1GITHASH="\"$(GIT_HASH)\"" -DMK1VERSION="\"$(VERSION)\""

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = MK1

MK1_FILES = src/Tweak.x # i cant remember why but the other files are just included into Tweak.x (???????) wtf. it works ig
MK1_FRAMEWORKS = JavaScriptCore
MK1_LIBRARIES = rocketbootstrap
MK1_PRIVATE_FRAMEWORKS = AppSupport MediaRemote
MK1_CFLAGS = -fobjc-arc $(VERSION_FLAGS) -Wno-error=deprecated-declarations # FIXME because it still uses UIApplication keyWindow

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += mk1app mk1cli
include $(THEOS_MAKE_PATH)/aggregate.mk
