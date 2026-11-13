# CalendarBar Agent Guidelines

## Workspace & Repository
- **Workspace Directory:** `/Users/jhaladjian/Desktop/WORKSPACES/CalendarBar`
- **GitHub Repository:** `https://github.com/avenix/CalendarBar`
- **Primary Branch:** `main`

## Commands & Workflows
- **Pushing Changes:** ALWAYS use `make push` (or `make push MSG="commit message"`). Do not use raw manual git push unless troubleshooting.
- **Building:** Use `make build` (compiles `CalendarBar.app` via `build.sh`).
- **Restarting App:** Use `make restart` to kill existing instance and launch newly built version.
- **Login Items:**
  - Check status: `make status-login`
  - Enable launch at login: `make install-login`
  - Disable launch at login: `make uninstall-login`
