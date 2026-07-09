# AnyCar

Enable any installed app on the CarPlay screen. A `.deb` tweak that ships a
companion app where you flip a switch per app; enabled apps show up in an
AnyCar launcher grid on the car display.

> Use while parked or as a passenger. Forcing video/games onto the car screen
> while driving is exactly what Apple blocks CarPlay to prevent.

## What's in the box

```
AnyCar/
├── Makefile          aggregate (builds tweak + app into one .deb)
├── control           package metadata — rename the package/author here
├── App/              the companion app (Home-screen icon "AnyCar")
│   ├── ACAppListViewController   native inset-grouped list, search, All/Enabled filter
│   ├── ACAppCell                 icon + name + bundle id + UISwitch
│   ├── ACInstalledApps           enumerates user apps via LSApplicationWorkspace
│   ├── ACSettingsStore           shared plist writer + Darwin notify
│   └── entitlements.plist        private-API access on jailbreak
└── Tweak/            injected into SpringBoard
    ├── Tweak.xm                  detects car display, attaches the launcher
    ├── ACLauncherViewController  the app grid shown on the car screen
    ├── ACAppMirror               layer remoting: hosts the app's remote layer
    ├── ACTouchForwardingView     captures car-screen touches, injects HID events
    └── ACPrefs                   reads the shared plist, live-reloads on notify
```

## How it works (short version)

1. Companion app lists user apps and writes the enabled bundle IDs to a shared
   plist (`/var/mobile/Library/Preferences/com.dan9.anycar.plist`), then
   posts a Darwin notification.
2. The tweak (inside SpringBoard) reads that list and draws a launcher grid on
   the car display.
3. Tapping an app: launch it, grab its scene's **remote layer** via
   `FBSceneContextHostManager -hostLayerForRequester:`, add that layer to a
   window bound to the car display, resize the scene, and keep it foregrounded.
   The app renders itself — we only relocate its output. Touches on the car
   screen are captured and re-injected as HID events into that scene.

This only works because the code runs inside SpringBoard with root, where every
app's render context and the displays/input are reachable. A sandboxed
(TrollStore, no root) app cannot host another process's layer, which is why the
full-mirror experience needs a jailbreak.

## Build

Requires [Theos](https://theos.dev) on macOS or Linux with an iOS SDK.

```sh
# set the target device once (or use THEOS_DEVICE_IP / on-device build)
export THEOS_DEVICE_IP=<iphone-ip>
make package        # produces packages/com.dan9.anycar_0.1.0_iphoneos-arm.deb
make package install
```

### Rootless (iOS 15+, Dopamine/palera1n rootless)

Add `THEOS_PACKAGE_SCHEME=rootless` to the make invocation. Paths move under
`/var/jb`. The shared prefs path under `/var/mobile/Library/Preferences` still
works because both processes run as `mobile`.

## Status — read this before you flash it

The companion app is complete and should build as-is.

The tweak is a correct-shape skeleton with the real mechanism wired, but three
spots are **version-sensitive and need on-device testing** (each marked
`TODO(device)` or `// VERSION:` in the source):

1. **Car-display discovery / window binding** (`Tweak.xm`) — the UIScreen path
   works on iOS 14-16; iOS 17/18 usually needs the `CAWindowServer` →
   `CADisplay` → `UIScreen` bridge, left as a hook.
2. **Scene resize** (`ACAppMirror -resizeSceneToCarDisplay`) — needs the
   concrete `FBMutableSceneSettings` selectors for your firmware, otherwise the
   app renders at phone size on the car screen.
3. **Touch routing to a specific scene** (`ACTouchForwardingView -routeHIDEvent:toScene:`)
   — the one genuinely hard part. HID event creation is done; routing the event
   to the mirrored scene (rather than the main display) differs on iOS 17/18
   (deferring/eligibility tokens) and is intentionally left unimplemented.

For the concrete selectors, diff a FrontBoard/BackBoard/SpringBoardServices
headers dump for your exact iOS version against the declarations in
`Tweak/PrivateHeaders.h`.

## Credits & Dependencies

This tweak is built on top of the iOS jailbreak development ecosystem and utilizes several key components:

- **Author / Maintainer**: DAN9 (customized metadata, assets, and compiled code).
- **Build System**: [Theos](https://theos.dev) development suite.
- **Hooking & Injection**: `mobilesubstrate` (Cydia Substrate / Ellekit / Substitute) to inject code into SpringBoard.
- **Touch Event Injection**: Private `IOHIDEvent` APIs and headers originally reverse-engineered and documented by [KennyTM~](https://github.com/kennytm) (via custom `IOHIDEvent.h` declarations).
- **Apple Private Frameworks**:
  - `FrontBoard` (for scene management: `FBScene`, `FBSceneContextHostManager`, `FBSceneManager`).
  - `SpringBoardServices` (for starting applications via `SBSLaunchApplicationWithIdentifier`).
  - `CoreServices` (for app listing via `LSApplicationWorkspace`).
  - `QuartzCore` (for UI mirroring via `CALayerHost`).
```
