# btsleep

Stop a MacBook from waking up every 12 seconds while it sleeps. btsleep turns Bluetooth off when the Mac goes to sleep and turns it back on when you open the lid.

I wrote it for my M5 Pro MacBook Pro after it lost battery overnight with the lid closed. If your Mac drains its battery in sleep and `pmset -g log` is full of `centauri` wake reasons, this is probably the same bug.

## The problem

One morning my MacBook Pro (Mac17,8, macOS 27.0.1) had lost 7% overnight with the lid closed. `pmset -g log` showed why. The Mac had woken itself about 3,600 times in 12 hours, roughly 290 times an hour, and every wake had the same reason:

```
DarkWake from Deep Idle [CDN] : due to smc.sysState.Wake(0x70070000) wifibt SMC.OutboxNotEmpty centauri-beta/ Using BATT (Charge:65%) 5 secs
```

A DarkWake is a wake with the screen off. Each one lasted 3 to 8 seconds, then the Mac went back to sleep for about 5 seconds, then the next wake came. So the Mac was awake about half the night. `wifibt` and `centauri` point at the combined Wi-Fi and Bluetooth chip.

I am not the only one. Other people see the same log lines on M5 Pro MacBook Pros, some with 20 to 30% drain per night. See the [references](#references). Apple has not commented on it, as far as I can find.

Turning Bluetooth off and on in Control Center stops the loop. It came back for me after a while, and I did not want to do that by hand every evening. So btsleep does it.

### Do you have this bug?

Close the lid for two minutes, open it, and run:

```sh
pmset -g log | grep DarkWake | tail -20
```

If you see a `centauri-alpha` or `centauri-beta` DarkWake every 10 to 15 seconds, you have it. To count all of them in the log:

```sh
pmset -g log | grep -c centauri
```

## What btsleep does

- Just before the Mac sleeps, it turns Bluetooth off. It holds sleep until Bluetooth is off, through the IOKit sleep notification.
- When the screen wakes, it turns Bluetooth back on. A DarkWake does not wake the screen, so Bluetooth stays off for the whole night.
- It only turns Bluetooth on if btsleep turned it off. If you had Bluetooth off yourself, it stays off.

In my test, the Mac woke every 12 seconds without btsleep. With btsleep, it woke one to three times in the first minute and then slept until I opened the lid.

It is one Swift file of about 70 lines, with no dependencies. A LaunchAgent starts it at login.

## Requirements

- A Mac with Apple Silicon. I tested it on a MacBook Pro Mac17,8 (M5 Pro) with macOS 27.0.1.
- The Xcode Command Line Tools for `swiftc`. Run `xcode-select --install` if you do not have them. You need them for both install methods, because Homebrew builds btsleep from source.

## Install

With Homebrew:

```sh
brew install elmarbeckmann/tap/btsleep
brew services start btsleep
```

macOS may ask you to allow Bluetooth access for btsleep the first time it runs.

### From source

```sh
git clone https://github.com/elmarbeckmann/btsleep.git
cd btsleep
make install
```

`make install` builds the binary, copies it to `~/.local/bin/btsleep`, writes the LaunchAgent to `~/Library/LaunchAgents/dev.elmar.btsleep.plist` and starts it.

You can delete the clone folder after the install. To put the binary somewhere else, run `make install PREFIX=/some/path`. It then goes to `/some/path/bin/btsleep`.

Use one of the two methods, not both, because two copies would both switch Bluetooth.

## Check that it works

With Homebrew, the log is at `$(brew --prefix)/var/log/btsleep.log`:

```sh
tail "$(brew --prefix)/var/log/btsleep.log"
```

With the install from source, it is at `~/Library/Logs/btsleep.log`:

```sh
tail ~/Library/Logs/btsleep.log
```

After you close and open the lid, the log shows lines like these. The times are in your local time.

```
2026-11-02T08:48:46+01:00 started, bluetooth power = 1
2026-11-02T08:49:45+01:00 sleep: bluetooth off
2026-11-02T08:51:02+01:00 wake: bluetooth on
```

The next morning, `pmset -g log | grep -c centauri` should grow by a few per hour, not by hundreds.

## Turn it off

With Homebrew, to stop it and keep it from starting at the next login:

```sh
brew services stop btsleep
```

Run `brew services start btsleep` to turn it on again. To remove it completely:

```sh
brew services stop btsleep && brew uninstall btsleep
```

With the install from source, to stop it and keep it from starting at the next login:

```sh
launchctl disable gui/$(id -u)/dev.elmar.btsleep
launchctl bootout gui/$(id -u)/dev.elmar.btsleep
```

Run `make install` to turn it on again.

To remove it completely:

```sh
make uninstall
```

This also removes the binary and the state file. The log stays in `~/Library/Logs/btsleep.log`.

## Limitations

- btsleep uses a private Apple function to switch Bluetooth, `IOBluetoothPreferenceSetControllerPowerState`. [blueutil](https://github.com/toy/blueutil) uses the same one. A macOS update can remove it. If that happens, the log says `IOBluetooth power functions not found`.
- A Bluetooth keyboard or mouse cannot wake the Mac while it sleeps, because Bluetooth is off.
- It does not fix the bug in macOS. It only avoids it. When Apple fixes the bug, you do not need btsleep anymore.

## Other ways to fix it

- Turn Bluetooth off and on in Control Center when it happens. This is enough if the loop does not come back for you.
- [sleepwatcher](https://www.bernhard-baehr.de/) with [blueutil](https://github.com/toy/blueutil). Both are on Homebrew. sleepwatcher runs a script when the Mac sleeps and wakes, and blueutil switches Bluetooth. This is the classic way to do it and does the same as btsleep.
- [BluetoothGuardian](https://github.com/hustuhao/BluetoothGuardian) turns Bluetooth off when the screen turns off. It is written in Go and needs blueutil.

I wanted a single small program without dependencies, so I built my own.

## References

Reports of the same bug:

- [MacBook Pro M5 Pro: DarkWake causing overnight battery drain](https://discussions.apple.com/thread/256265048), Apple Community
- [Centauri-Alpha prevents sleep](https://forums.macrumors.com/threads/centauri-alpha-prevents-sleep.2482169/), MacRumors Forums
- [MacBook Air M4 - Battery Drain During Sleep](https://developer.apple.com/forums/thread/787549), Apple Developer Forums. Same `wifibt SMC.OutboxNotEmpty` wake reason on an M4 MacBook Air.

Apple documentation for the APIs btsleep uses:

- [Technical Q&A QA1340: Registering and unregistering for sleep and wake notifications](https://developer.apple.com/library/archive/qa/qa1340/_index.html)
- [NSWorkspace.screensDidWakeNotification](https://developer.apple.com/documentation/appkit/nsworkspace/screensdidwakenotification)

## Credits

I made btsleep with help from [Claude](https://claude.ai). Claude helped me read the power log, find the other reports and write the code. I tested it on my own MacBook.

## License

MIT. See [LICENSE](LICENSE).
