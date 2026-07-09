include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AnyCar

AnyCar_FILES = Tweak.xm ACPrefs.m ACAppMirror.m ACTouchForwardingView.m ACLauncherViewController.m
AnyCar_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
AnyCar_FRAMEWORKS = UIKit QuartzCore CoreFoundation
AnyCar_PRIVATE_FRAMEWORKS = IOKit SpringBoardServices
# FrontBoard / BackBoard / SpringBoardServices symbols resolve at runtime via
# the private headers; no extra link flags required for the objc_msgSend paths.

include $(THEOS_MAKE_PATH)/tweak.mk
