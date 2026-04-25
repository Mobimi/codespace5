TARGET := iphone:clang:latest:14.0
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = PerformanceHUD

PerformanceHUD_FILES = Tweak.x
PerformanceHUD_CFLAGS = -fobjc-arc
PerformanceHUD_FRAMEWORKS = UIKit QuartzCore Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
