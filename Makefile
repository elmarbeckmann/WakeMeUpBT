UID := $(shell id -u)
PREFIX ?= $(HOME)/.local
BIN := $(PREFIX)/bin/btsleep
PLIST := $(HOME)/Library/LaunchAgents/dev.elmar.btsleep.plist
LOG := $(HOME)/Library/Logs/btsleep.log
STATE := $(HOME)/Library/Application Support/btsleep

.PHONY: build install uninstall clean

build: btsleep

btsleep: btsleep.swift
	swiftc -O -o btsleep btsleep.swift

install: build
	install -d $(PREFIX)/bin
	install -m 755 btsleep $(BIN)
	sed -e 's#__BIN__#$(BIN)#' -e 's#__LOG__#$(LOG)#' dev.elmar.btsleep.plist > $(PLIST)
	-launchctl bootout gui/$(UID)/dev.elmar.btsleep 2>/dev/null || true
	launchctl enable gui/$(UID)/dev.elmar.btsleep
	launchctl bootstrap gui/$(UID) $(PLIST)

uninstall:
	-launchctl bootout gui/$(UID)/dev.elmar.btsleep 2>/dev/null || true
	rm -f $(PLIST) $(BIN)
	rm -rf "$(STATE)"

clean:
	rm -f btsleep
