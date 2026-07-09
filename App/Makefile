include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = AnyCar

AnyCar_FILES = main.m ACAppDelegate.m ACAppListViewController.m ACAppCell.m ACInstalledApps.m ACSettingsStore.m
AnyCar_FRAMEWORKS = UIKit CoreFoundation QuartzCore
AnyCar_CFLAGS = -fobjc-arc
# LSApplicationWorkspace lives in MobileCoreServices / CoreServices; it resolves at
# runtime via the private headers, no extra link flag strictly required, but keep
# CoreServices linked for the symbol availability.
AnyCar_FRAMEWORKS += CoreServices
AnyCar_INSTALL_PATH = /Applications
# Jailbroken apps must be signed with wildcard entitlements to reach private APIs.
AnyCar_CODESIGN_FLAGS = -Sentitlements.plist

include $(THEOS_MAKE_PATH)/application.mk
