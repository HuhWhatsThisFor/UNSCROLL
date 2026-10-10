# Validation — October 9, 2026

## Passed

- `swift test`: **24 core tests, zero failures**.
- Xcode hosted tests on **iPhone 17 / iOS 26.4 Simulator**: **24 tests, zero failures**.
- Preview UI integration test: **1 test, zero failures**, covering onboarding, simulated individual authorization, selecting a demo distraction, starting focus, confirming early stop, honest history, Settings, and Privacy. The screenshots in `Docs/Preview` are actual XCTest captures, not design mockups or seeded usage data.
- `UNSCROLL Preview` simulator build, including its embedded DeviceActivity Monitor extension.
- `UNSCROLL Live` device configuration compiler build, including the monitor, in both Debug and Release. These builds disabled code signing for compilation only and were not installed or used to exercise restricted APIs.
- Xcode project parses and lists all four targets and four configurations.
- App icon is an opaque 1024 × 1024 PNG.
- Read-only provisioning check CLI parses and exposes its documented arguments.

The installed toolchain changed during this session: initial compiler builds used Xcode 26.6 / Swift 6.3.3; final builds and simulator tests used Xcode 27.0 (27A266a) / Swift 6.4. Project language mode remains Swift 6, minimum deployment remains iOS 17. No compiler errors were suppressed. Xcode emits an expected metadata notice because the app does not use AppIntents.

## Not verified here

Preview was successfully signed, installed, and launched on a physical iPhone using free Personal Team provisioning. Its app and monitor signed entitlements contain neither Family Controls nor App Groups. The owner confirmed the Preview UI works; the full manual checklist remains in `Docs/PHYSICAL_IPHONE_TEST.md`.

Automatic Live provisioning was subsequently attempted for both targets and failed with Xcode's explicit statement that Personal development teams do not support Family Controls (Development). Existing Preview profiles also lack App Groups and Family Controls. Apple's current capability matrix lists App Groups as available to free accounts; that does not grant Family Controls access. No valid Live binary was produced or installed. No live authorization, actual system shield enforcement, physical-device expiry, App Store distribution, or minimum-iOS-17 device run is claimed.

Use the README's provisioning checklist and physical-device acceptance steps before treating live blocking as validated. Apple controls background callback delivery; exact-second expiration while terminated is not promised.

Large accessibility sizes, comprehensive VoiceOver navigation, and older/smaller physical iPhones still need the documented manual acceptance checks. SwiftUI layouts use scalable typography and scrolling; the timer, progress, chart, and picker choices have explicit accessibility descriptions.

## Reproduce

```sh
swift test
xcodebuild -project UNSCROLL.xcodeproj -scheme 'UNSCROLL Preview' \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.4' \
  -derivedDataPath .build-xcode-tests CODE_SIGNING_ALLOWED=NO test
xcodebuild -project UNSCROLL.xcodeproj -scheme 'UNSCROLL Live' \
  -configuration 'Live Release' -destination 'generic/platform=iOS' \
  -derivedDataPath .build-xcode CODE_SIGNING_ALLOWED=NO build
```

The unsigned device command is a compiler check, not a signing workaround. Actual installation requires normal valid profiles and signing, as described in README.md.

## Open-source release preparation

- Re-ran `swift test`: **24 tests, zero failures**.
- Re-ran Preview tests on iPhone 17 / iOS 26.4 Simulator: **24 hosted core tests and 1 UI flow test, zero failures**; the app and embedded monitor built successfully.
- Verified all 31 application, resource, shared-core, monitor, test, package, Live configuration/entitlement, Preview entitlement, and project-definition files against their pre-cleanup hashes. No functional source changes were made.
- Audited the whole working directory, including generated files. Personal signing metadata and provisioning profiles were found locally; they are excluded from release. The public configuration no longer embeds a personal team identifier, and the physical-device document omits signing identity and process details.
- The release candidate contains 46 files. Pattern checks found no private keys, recognizable GitHub/AWS credentials, personal email addresses, home-directory paths, personal device identifiers, or personal developer-account identifiers in those files. The local signing override, provisioning profiles, Xcode user state, and build/test caches are ignored.
- Reviewed the Preview screenshots visually and inspected PNG metadata: only generic screenshot, orientation, and image dimension metadata is present. No personal data or location metadata was found.
- Verified documentation links resolve to local files and the provisioning-check CLI accepts its documented arguments.
- There was no existing Git repository or history to audit. A local Git repository was initialized for the cleaned project. Publication is paused for owner review because the audit found personal signing metadata before cleanup; no GitHub repository or remote push has been created during preparation.
