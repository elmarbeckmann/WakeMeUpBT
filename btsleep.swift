// btsleep: turn Bluetooth off before system sleep and on again at full wake.
// Workaround for the wifibt/centauri DarkWake loop on M5 MacBook Pros.
// Build: make   (see README.md)
import AppKit
import IOKit.pwr_mgt

setvbuf(stdout, nil, _IONBF, 0)

// Private IOBluetooth API, the same one that blueutil uses. Loaded at runtime so a
// macOS update that removes it gives a clear error instead of a link failure.
typealias GetPower = @convention(c) () -> Int32
typealias SetPower = @convention(c) (Int32) -> Void
let lib = dlopen("/System/Library/Frameworks/IOBluetooth.framework/IOBluetooth", RTLD_LAZY)
guard let g = dlsym(lib, "IOBluetoothPreferenceGetControllerPowerState"),
      let s = dlsym(lib, "IOBluetoothPreferenceSetControllerPowerState") else {
    fatalError("IOBluetooth power functions not found")
}
let getPower = unsafeBitCast(g, to: GetPower.self)
let setPower = unsafeBitCast(s, to: SetPower.self)

func log(_ msg: String) { print("\(Date()) \(msg)") }

// IOKit message constants are C macros that Swift does not import.
let kCanSystemSleep: UInt32 = 0xE000_0270
let kSystemWillSleep: UInt32 = 0xE000_0280

// True only when this program turned Bluetooth off. DarkWakes put the system to
// sleep again while Bluetooth is off; the flag keeps us from losing the user's state.
var turnedOff = false
var rootPort: io_connect_t = 0
var notifyPort: IONotificationPortRef?
var notifier: io_object_t = 0

rootPort = IORegisterForSystemPower(nil, &notifyPort, { _, _, type, arg in
    switch type {
    case kCanSystemSleep:
        IOAllowPowerChange(rootPort, Int(bitPattern: arg))
    case kSystemWillSleep:
        if !turnedOff && getPower() == 1 {
            setPower(0)
            turnedOff = true
            log("sleep: bluetooth off")
        }
        IOAllowPowerChange(rootPort, Int(bitPattern: arg))
    default:
        break
    }
}, &notifier)
guard rootPort != 0 else { fatalError("IORegisterForSystemPower failed") }
CFRunLoopAddSource(CFRunLoopGetMain(), IONotificationPortGetRunLoopSource(notifyPort).takeUnretainedValue(), .defaultMode)

// Screens wake only at a full (user) wake, not at a DarkWake.
NSWorkspace.shared.notificationCenter.addObserver(
    forName: NSWorkspace.screensDidWakeNotification, object: nil, queue: .main
) { _ in
    if turnedOff {
        setPower(1)
        turnedOff = false
        log("wake: bluetooth on")
    }
}

log("started, bluetooth power = \(getPower())")
// NSWorkspace delivers screen wake notifications only to a process with an
// NSApplication. The policy keeps it out of the Dock and the app switcher.
NSApplication.shared.setActivationPolicy(.prohibited)
NSApplication.shared.run()
