UID := $(shell id -u)
PREFIX ?= $(HOME)/.local
BIN := $(PREFIX)/bin/wakemeupbt
PLIST := $(HOME)/Library/LaunchAgents/dev.elmar.wakemeupbt.plist
LOG := $(HOME)/Library/Logs/wakemeupbt.log
STATE := $(HOME)/Library/Application Support/wakemeupbt

.PHONY: build install uninstall clean

build: wakemeupbt

wakemeupbt: wakemeupbt.swift
	swiftc -O -o wakemeupbt wakemeupbt.swift

install: build
	install -d $(PREFIX)/bin
	install -m 755 wakemeupbt $(BIN)
	sed -e 's#__BIN__#$(BIN)#' -e 's#__LOG__#$(LOG)#' dev.elmar.wakemeupbt.plist > $(PLIST)
	-launchctl bootout gui/$(UID)/dev.elmar.wakemeupbt 2>/dev/null || true
	launchctl enable gui/$(UID)/dev.elmar.wakemeupbt
	launchctl bootstrap gui/$(UID) $(PLIST)

uninstall:
	-launchctl bootout gui/$(UID)/dev.elmar.wakemeupbt 2>/dev/null || true
	rm -f $(PLIST) $(BIN)
	rm -rf "$(STATE)"

clean:
	rm -f wakemeupbt
