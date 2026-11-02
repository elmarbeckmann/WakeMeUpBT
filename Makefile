UID := $(shell id -u)
PLIST := $(HOME)/Library/LaunchAgents/local.btsleep.plist
LOG := $(HOME)/Library/Logs/btsleep.log

.PHONY: build install uninstall clean

build: btsleep

btsleep: btsleep.swift
	swiftc -O -o btsleep btsleep.swift

install: build
	sed -e 's#__BIN__#$(CURDIR)/btsleep#' -e 's#__LOG__#$(LOG)#' local.btsleep.plist > $(PLIST)
	-launchctl bootout gui/$(UID)/local.btsleep 2>/dev/null || true
	launchctl enable gui/$(UID)/local.btsleep
	launchctl bootstrap gui/$(UID) $(PLIST)

uninstall:
	-launchctl bootout gui/$(UID)/local.btsleep 2>/dev/null || true
	rm -f $(PLIST)

clean:
	rm -f btsleep
