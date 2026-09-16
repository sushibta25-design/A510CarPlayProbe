ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:15.0
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = A510CarPlayProbe
A510CarPlayProbe_FILES = Tweak.xm
A510CarPlayProbe_CFLAGS = -fobjc-arc
A510CarPlayProbe_FRAMEWORKS = Foundation UIKit

include $(THEOS_MAKE_PATH)/tweak.mk
