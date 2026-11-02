# btsleep

Turns Bluetooth off when a Mac goes to sleep and back on when you wake it.

## Why

On some Apple Silicon MacBooks (reported on M5 Pro, macOS 26 and 27) the Wi-Fi/Bluetooth chip wakes the Mac every ~12 seconds during sleep. `pmset -g log` shows this:

```
DarkWake from Deep Idle ... due to smc.sysState.Wake(0x70070000) wifibt SMC.OutboxNotEmpty centauri-beta/
```

The author measured about 290 such wakes per hour overnight. Turning Bluetooth off and on stops the loop. btsleep does that automatically.

Reports:

- https://discussions.apple.com/thread/256265048
- https://forums.macrumors.com/threads/centauri-alpha-prevents-sleep.2482169/

## How it works

- It hooks system sleep through IOKit and waits until Bluetooth is off before it allows sleep.
- It turns Bluetooth on again at full wake only. A DarkWake does not turn it on.
- It restores Bluetooth only if btsleep turned it off.

## Requirements

- macOS on Apple Silicon (tested on macOS 27.0.1, MacBook Pro Mac17,8)
- Xcode Command Line Tools (`swiftc`)

No other dependencies.

## Install

```
git clone <repository-url> btsleep
cd btsleep
make install
```

The binary stays in the clone folder. Do not move or delete the folder after install. If you move it, run `make install` again.

macOS may ask for Bluetooth permission.

## Check it works

```
tail ~/Library/Logs/btsleep.log
```

The log shows `started`, `sleep: bluetooth off` and `wake: bluetooth on`. Times are UTC.

To count the wakes:

```
pmset -g log | grep -c centauri
```

## Disable without uninstalling

```
launchctl disable gui/$(id -u)/local.btsleep
launchctl bootout gui/$(id -u)/local.btsleep
```

Run `make install` to enable it again.

## Uninstall

```
make uninstall
```

## Limitations

- It uses a private Apple API (the same one blueutil uses). A macOS update can remove it. The log then shows "IOBluetooth power functions not found".
- If btsleep restarts while the Mac sleeps, it forgets that it turned Bluetooth off. Bluetooth then stays off until you turn it on.
- Bluetooth keyboards and mice cannot wake the Mac while it sleeps.

## Alternatives

- sleepwatcher + blueutil: https://github.com/toy/blueutil
- BluetoothGuardian: https://github.com/hustuhao/BluetoothGuardian

## License

MIT. See LICENSE.
