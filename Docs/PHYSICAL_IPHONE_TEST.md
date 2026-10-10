# Physical iPhone testing — Phase 1

Prepared October 9, 2026, using the **UNSCROLL Preview** scheme. Manual functional testing remains for the owner to perform.

## Verified setup and results

| Item | Result |
| --- | --- |
| Xcode | 27.0, build 27A266a |
| Swift | 6.4 |
| Target | USB-connected iPhone 13 Pro Max, named iPhone, iOS 26.6.2 |
| Device readiness | Paired/trusted, booted, available as an Xcode destination; passcode not required at readiness check |
| Developer Mode | Enabled; developer disk image services available |
| Scheme | UNSCROLL Preview, Run configuration Preview Debug |
| Signing | Automatic, local Personal Team (identity omitted) |
| Signed build | Succeeded for the USB iPhone; app and embedded monitor signatures verified |
| Preview entitlements | Neither Family Controls nor App Groups in the signed app or monitor |
| Installation | Xcode Run installed UNSCROLL 1.0.0 (1), bundle identifier org.unscroll.app |
| Launch | App process verified on the physical iPhone |

Personal signing details belong in ignored local configuration files, following the setup in `README.md`. Live configuration, project target definitions, extension targets, and functional app code were preserved. No data reset or uninstallation was performed. No membership was purchased or created.

Free development provisioning profiles expire seven days after issuance. To renew, connect the iPhone, select **UNSCROLL Preview → your iPhone** in Xcode and use **Product → Run**. Do not delete the app to renew signing.

## Manual test checklist

If onboarding appears, tap **Continue** through the introduction. On the permission page, tap **Simulate permission**, then **Continue**. Tap **Choose demo apps**, select at least one illustrative choice, tap **Save**, then **Find your focus**. These choices and permission are simulated.

1. Open **Home**. Confirm the Preview banner and daily focus dashboard appear.
2. Open **History**, then **Settings**, then return to **Home**. Confirm each page loads.
3. Select **25 min** and tap **Start demo focus**. If disabled, use **Enable demo permission** and select at least one demo choice under **Your distractions**.
4. Confirm the timer starts near **25:00** and decreases. Note the displayed finish time.
5. Return to the iPhone Home Screen and reopen UNSCROLL. For a stronger persistence check, also swipe up and pause to open the app switcher, swipe UNSCROLL upward to force-close it, and reopen from its icon.
6. Confirm **Demo session running** appears. Tap **Return to focus** and verify the same finish time and a remaining duration reduced by elapsed time; it must not restart at 25:00.
7. Tap **End session early**, then confirm **End session**. Tap **Back to your day** afterward.
8. Open **History**. Confirm **Ended early**, **Preview session · simulated**, **Planned focus: 25 min**, and actual elapsed duration (**Under 1m** if stopped within a minute). Early sessions should not increase completed focus totals or streaks.
9. Open **Settings** and change **Daily goal**, for example from 60 to 90 minutes. Confirm the new value and Home goal agree.
10. Force-close UNSCROLL using the app switcher and reopen it. Confirm the daily goal remains saved and the early-ended session remains in History.

Do not wait 25 minutes for this checklist. No manual test steps above were automated during preparation.

## Manual setup actions and Live blockers

No Apple Account sign-in, device trust, or Developer Mode intervention was needed for the successful installation and launch. Open UNSCROLL on the iPhone if it is no longer foreground, then perform the checklist.

Preview cannot block apps. A subsequent Live development signing attempt failed because Personal Teams do not support Family Controls (Development). Live requires an eligible Apple Developer Program team and profiles containing Family Controls and the shared App Group for both the app and monitor. Apple's current capability matrix lists App Groups as available to free accounts, but the Preview profiles do not contain that capability. Actual authorization, shielding, and monitor expiration still need separate physical-device validation with valid Live provisioning. Distribution additionally requires Apple's Family Controls approval for the app and relevant Screen Time extensions.

References: [Apple developer account overview](https://developer.apple.com/help/account/basics/about-your-developer-account), [Configuring Family Controls](https://developer.apple.com/documentation/xcode/configuring-family-controls), and [Requesting the Family Controls entitlement](https://developer.apple.com/documentation/familycontrols/requesting-the-family-controls-entitlement).
