# Contributing to UNSCROLL

UNSCROLL is a free, MIT-licensed iPhone focus app. Development is currently paused pending eligible Apple Developer Program signing for real Screen Time validation. The existing Preview, Live integration, monitor, and tests are preserved so the project can resume.

## Useful contributions

- Accessibility: Dynamic Type, VoiceOver navigation, Reduce Motion, contrast, and smaller iPhone layouts.
- Session reliability: persistence, early stop, permission changes, delayed monitor callbacks, and foreground recovery.
- Genuine Live device validation by contributors who already have an eligible signing team and choose to test on their own devices.
- Clearer documentation, reproducible bug reports, and focused regression fixes.

Discuss substantial changes in an issue before implementing them. Keep pull requests focused and preserve existing behavior unless the change is explicitly described. Never present simulated restrictions as real app blocking.

## Setup

1. Fork and clone the repository, then open `UNSCROLL.xcodeproj` from the project root.
2. Use Xcode with Swift 6 and an iOS 26.4 or newer SDK; Xcode 27.0 / Swift 6.4 is the tested toolchain. The app deploys to iOS 17 or later.
3. Select **UNSCROLL Preview** and an installed iPhone simulator. No signing account or paid membership is required for this mode.
4. Run onboarding, simulate permission, select a demo choice, and start a demo focus session.

Personal-device signing belongs in ignored `Config/Local.xcconfig` or `Config/Preview.local.xcconfig`, following `README.md`. Keep the generic `Config/Local.xcconfig.example` free of personal details. No backend, API keys, subscriptions, or external packages are required.

## Checks before a pull request

From the project root:

```sh
swift test
xcodebuild -project UNSCROLL.xcodeproj -scheme 'UNSCROLL Preview' \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath .build-xcode CODE_SIGNING_ALLOWED=NO build
git diff --check
git status --short
git diff --cached
```

For UI changes, run **Product → Test** with the Preview scheme on an iPhone simulator and describe the relevant manual checks. Add a regression test when it proves a meaningful behavior change; do not rewrite unrelated features. See `VALIDATION.md` for current test coverage.

Live changes require honest validation reporting: compilation alone does not establish authorization, provisioning, shielding, or background expiration. A free Personal Team cannot sign Family Controls development. Do not remove restricted entitlements, bypass Apple security, or replace real services with mocks to make a Live test appear to pass. Do not automate blocking tests on another person's device. Apple controls monitor delivery, so exact-second background unblocking is not guaranteed.

## Reporting bugs and validation

Include the scheme, Xcode/Swift versions, iOS version, steps to reproduce, expected behavior, actual behavior, and relevant sanitized diagnostics. State whether a result came from a simulator, physical Preview, or a validly provisioned Live build. If Live was used, report whether signed entitlement checks passed without sharing the profiles themselves.

Remove credentials, account names and email addresses, developer team IDs, device serial numbers/UDIDs, personal absolute paths, selected app tokens, and personal session history from logs and screenshots. Use generic sample identifiers. Never attach provisioning profiles, private keys, signing certificates, or developer-account exports. If a credential is exposed, revoke it through its issuer and notify the owner privately rather than reproducing it in a public issue.

## Pull requests

Explain the problem, resulting behavior, checks performed, and any remaining limits. Include screenshots for visible changes, with mock data and no personal information. Keep shared schemes, the monitor target, Preview/Live configurations, and existing tests intact.

No CI service, GitHub Actions workflow, or paid product is required. Run checks locally and record the results. Contributions are accepted under the project's MIT license; retain license notices.
