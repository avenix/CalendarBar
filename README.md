# CalendarBar

A lightweight, native macOS menu bar app that displays your upcoming calendar event directly in the task/menu bar.

## Features
- **Live Status:** Displays next event (`📅 2:00 PM Design Sync`) or ongoing event (`🔴 Sprint Review (until 11:30 AM)`).
- **Native & Fast:** Written in Swift using Apple's `NSStatusItem` and `EventKit`.
- **Zero Clutter:** Runs purely as a menu bar agent (`LSUIElement = true`), with no icon in the Dock.
- **Smart Link Detection:** Automatically detects video call links (Zoom, Google Meet, Teams, Webex) in the event URL or notes and offers a one-click "Join Meeting" button in the menu.
- **Automatic Sync:** Refreshes on an interval and immediately updates whenever calendar database events change.

## Building and Running
Run the build script:
```bash
./build.sh
```
To launch the app:
```bash
open CalendarBar.app
```

## Launch at Login
1. Open **System Settings** -> **General** -> **Login Items & Extensions**.
2. Under **Open at Login**, click `+` and choose `CalendarBar.app`.
