export TARGET = iphone:clang::11.0
export ARCHS = arm64 arm64e

export ADDITIONAL_CFLAGS = -I$(THEOS_PROJECT_DIR)/Headers

NSTALL_TARGET_PROCESSES = SpringBoard

VERSION = "9.9.9"
GIT_HASH = `git rev-parse HEAD`
export VERSION_FLAGS=-DMK1GITHASH="\"$(GIT_HASH)\"" -DMK1VERSION="\"$(VERSION)\""

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = MK1
MK1_FILES = tweak/Tweak.x $(wildcard tweak/*.m)
MK1_CFLAGS = -fobjc-arc $(VERSION_FLAGS) -Wno-error=deprecated-declarations
MK1_FRAMEWORKS = JavaScriptCore
MK1_LIBRARIES = rocketbootstrap
MK1_PRIVATE_FRAMEWORKS = AppSupport MediaRemote

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += app cli-tool
include $(THEOS_MAKE_PATH)/aggregate.mk
