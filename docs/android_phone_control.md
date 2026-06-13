# Android Phone Control

ALTER now has a native Android phone-control layer with three parts:

1. Foreground wake service for `Hey Alter`.
2. Accessibility service for visible screen reading, taps, scrolling, typing, and global navigation.
3. Device-control bridge for app/settings/dialer/SMS intents and Accessibility actions.

## Native Channels

- `alter.ai/device_control`
  - `isAccessibilityEnabled`
  - `openAccessibilitySettings`
  - `openApp`
  - `openSettings`
  - `openDialer`
  - `openSmsDraft`
  - `readScreen`
  - `executeAccessibilityAction`

## Consent Model

ALTER cannot use Accessibility until the user enables `ALTER phone control` in Android Settings. When enabled, the app can read visible screen text and perform UI actions only through Android's Accessibility APIs. Every Flutter-side phone-control attempt is recorded in the local Phone Control audit panel in OpenClaw.

## Agent Tools

The agent planner can now call tools for:

- Opening apps and settings.
- Reading visible screen text.
- Clicking visible text.
- Typing into focused fields.
- Scrolling.
- Pressing Back, Home, Recents, Notifications, and Quick Settings.

Direct clicks on high-impact labels such as Send, Pay, Confirm, Install, Approve, Delete, Allow, and Transfer are blocked in the agent tool executor. These actions must stay behind user confirmation or OpenClaw.

## OpenClaw Bridge

OpenClaw execution now tries to route confirmed actions into native device actions where there is a safe mapping. Unknown action types are still marked and audited, but ALTER does not pretend that unmapped actions were automated.
