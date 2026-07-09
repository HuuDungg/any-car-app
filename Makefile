# AnyCar - aggregate project (tweak + companion app)
export ARCHS = arm64 arm64e
export TARGET = iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

SUBPROJECTS += Tweak
SUBPROJECTS += App

include $(THEOS)/makefiles/aggregate.mk

after-install::
	install.exec "killall -9 SpringBoard || true"
