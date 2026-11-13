# CalendarBar

A lightweight, native macOS menu bar app that displays your upcoming calendar event directly in the task/menu bar.

## Features
- **Live Status:** Displays next event (`📅 2:00 PM Design Sync`) or ongoing event (`🔴 Sprint Review (until 11:30 AM)`).
- **Native & Fast:** Written in Swift using Apple's `NSStatusItem`, `EventKit`, and `ServiceManagement`.
- **Zero Clutter:** Runs purely as a menu bar agent (`LSUIElement = true`), with no icon in the Dock.
- **Smart Link Detection:** Automatically detects video call links (Zoom, Google Meet, Teams, Webex) in the event URL or notes and offers a one-click "Join Meeting" button in the menu.
- **Automatic Sync:** Refreshes on an interval and immediately updates whenever calendar database events change.
- **Launch at Login:** Toggle right from the menu bar item or via `make install-login`.

## Commands (Makefile)

| Command | Description |
| :--- | :--- |
| `make build` | Compiles the app into `CalendarBar.app` |
| `make run` | Builds and launches `CalendarBar.app` |
| `make restart` | Rebuilds and restarts the running app |
| `make kill` | Quits the running `CalendarBar` process |
| `make push` | Stages, commits, and pushes all changes (`make push MSG="commit message"`) |
| `make status-login` | Checks if CalendarBar is configured to run at login |
| `make install-login` | Registers CalendarBar to start automatically at login |
| `make uninstall-login` | Removes CalendarBar from login items |
| `make clean` | Removes compiled `CalendarBar.app` |

## Launch at Login
You can configure CalendarBar to start automatically when you log into your Mac in three ways:
1. **From the Menu Bar:** Click the CalendarBar icon and toggle `Launch at Login`.
2. **From Terminal:** Run `make install-login` (or `make uninstall-login` to remove).
3. **From System Settings:** Go to **System Settings** → **General** → **Login Items & Extensions**, click `+` under **Open at Login**, and select `CalendarBar.app`.
