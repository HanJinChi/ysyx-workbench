ARCH ?= native
FILE_MK = files.mk
FILE_TMP = .tmp.$(FILE_MK)
RTCONFIG_H = rtconfig.h

NAME = rtthread
SRCS = $(shell find src -name "*.c")
CFLAGS += -DHAVE_CCONFIG_H -D__RTTHREAD__
CFLAGS += -Wno-nonnull-compare
# LDFLAGS += -T extra.ld
-include $(FILE_MK)
-include am-apps.mk
include $(AM_HOME)/Makefile

$(RTCONFIG_H):
	touch $@
	scons --useconfig=.config
	if [ "`sed -n '3p' $@`"x = x ]; then sed -i -e '2a#include "extra.h"' $@; fi

init: $(RTCONFIG_H)
	scons -c
	scons --verbose -n > $(FILE_TMP)
	cat $(FILE_TMP) | grep -o '[^ ]*.c$$' | awk '{print "SRCS += " $$1}' > $(FILE_MK)
	cat $(FILE_TMP) | grep 'gcc ' | head -n 1 | grep -o " -I[^ ]*" | awk '{print "CFLAGS += " $$1}' >> $(FILE_MK)
	rm $(FILE_TMP)

menuconfig:
	scons --menuconfig
	scons --genconfig
	$(MAKE) init

update:
	python integrate-am-apps.py ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE)

.PHONY: init menuconfig
