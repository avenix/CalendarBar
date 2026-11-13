import AppKit
import EventKit
import ServiceManagement

class CalendarBarDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    let eventStore = EKEventStore()
    var refreshTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize menu bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateStatusIcon(isOngoing: false)
        if let button = statusItem.button {
            button.title = " Checking..."
        }

        // Request permissions and start
        checkAndRequestCalendarAccess()
    }

    func updateStatusIcon(isOngoing: Bool) {
        guard let button = statusItem?.button else { return }
        let symbolName = isOngoing ? "calendar.badge.clock" : "calendar"
        let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .regular)
        if let icon = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Calendar")?.withSymbolConfiguration(config) {
            icon.isTemplate = true
            button.image = icon
            button.imagePosition = .imageLeading
        }
    }

    func checkAndRequestCalendarAccess() {
        let status = EKEventStore.authorizationStatus(for: .event)
        
        if #available(macOS 14.0, *) {
            if status == .fullAccess {
                setupActiveMonitoring()
                return
            }
        } else {
            if status == .authorized {
                setupActiveMonitoring()
                return
            }
        }

        if status == .notDetermined {
            if #available(macOS 14.0, *) {
                eventStore.requestFullAccessToEvents { [weak self] granted, error in
                    DispatchQueue.main.async {
                        if granted {
                            self?.setupActiveMonitoring()
                        } else {
                            self?.showAccessDenied()
                        }
                    }
                }
            } else {
                eventStore.requestAccess(to: .event) { [weak self] granted, error in
                    DispatchQueue.main.async {
                        if granted {
                            self?.setupActiveMonitoring()
                        } else {
                            self?.showAccessDenied()
                        }
                    }
                }
            }
        } else {
            showAccessDenied()
        }
    }

    func setupActiveMonitoring() {
        updateNextEvent()
        
        // Refresh every 60 seconds
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.updateNextEvent()
        }

        // Listen for Calendar database changes (new invites, edits, deletes)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(calendarStoreChanged),
            name: .EKEventStoreChanged,
            object: eventStore
        )
    }

    @objc func calendarStoreChanged() {
        DispatchQueue.main.async { [weak self] in
            self?.updateNextEvent()
        }
    }

    func showAccessDenied() {
        updateStatusIcon(isOngoing: false)
        if let button = statusItem.button {
            button.title = " Cal Access Needed"
        }
        let menu = NSMenu()
        let info = NSMenuItem(title: "Calendar access is disabled.", action: nil, keyEquivalent: "")
        info.isEnabled = false
        menu.addItem(info)
        
        let settingsItem = NSMenuItem(title: "Open Privacy & Security Settings…", action: #selector(openSettings), keyEquivalent: "")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        let retryItem = NSMenuItem(title: "Retry Permission Check", action: #selector(retryAuth), keyEquivalent: "r")
        retryItem.target = self
        menu.addItem(retryItem)

        menu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc func retryAuth() {
        checkAndRequestCalendarAccess()
    }

    @objc func openSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc func updateNextEvent() {
        let now = Date()
        let calendar = Calendar.current
        
        // Query next 7 days
        guard let endDate = calendar.date(byAdding: .day, value: 7, to: now) else { return }
        let predicate = eventStore.predicateForEvents(withStart: now.addingTimeInterval(-60 * 60 * 4), end: endDate, calendars: nil)
        let allEvents = eventStore.events(matching: predicate)

        // Find active or upcoming events
        // 1. Current in-progress event (timed)
        let currentEvent = allEvents.filter { !$0.isAllDay && $0.startDate <= now && $0.endDate > now }
            .sorted { $0.endDate < $1.endDate }
            .first

        // 2. Next upcoming timed event
        let nextUpcoming = allEvents.filter { !$0.isAllDay && $0.startDate > now }
            .sorted { $0.startDate < $1.startDate }
            .first

        // 3. Next all-day event today (if no upcoming timed events today)
        let todayAllDay = allEvents.filter {
            $0.isAllDay && calendar.isDateInToday($0.startDate)
        }.first

        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short

        let menu = NSMenu()

        if let current = currentEvent {
            updateStatusIcon(isOngoing: true)
            let endTimeStr = timeFormatter.string(from: current.endDate)
            let truncated = truncate(current.title ?? "Meeting", limit: 20)
            statusItem.button?.title = " 🔴 \(truncated) (until \(endTimeStr))"

            buildEventDetailMenu(menu: menu, event: current, statusLabel: "Currently Happening (ends \(endTimeStr))")
        } else if let next = nextUpcoming {
            updateStatusIcon(isOngoing: false)
            let startTimeStr = timeFormatter.string(from: next.startDate)
            let truncated = truncate(next.title ?? "Event", limit: 22)
            
            if calendar.isDateInToday(next.startDate) {
                statusItem.button?.title = " \(startTimeStr) \(truncated)"
                buildEventDetailMenu(menu: menu, event: next, statusLabel: "Today at \(startTimeStr)")
            } else if calendar.isDateInTomorrow(next.startDate) {
                statusItem.button?.title = " Tomorrow: \(startTimeStr) \(truncated)"
                buildEventDetailMenu(menu: menu, event: next, statusLabel: "Tomorrow at \(startTimeStr)")
            } else {
                let df = DateFormatter()
                df.dateFormat = "EEE h:mm a"
                let dateStr = df.string(from: next.startDate)
                statusItem.button?.title = " \(dateStr) \(truncated)"
                buildEventDetailMenu(menu: menu, event: next, statusLabel: dateStr)
            }
        } else if let allDay = todayAllDay {
            updateStatusIcon(isOngoing: false)
            let truncated = truncate(allDay.title ?? "Event", limit: 24)
            statusItem.button?.title = " Today: \(truncated)"
            buildEventDetailMenu(menu: menu, event: allDay, statusLabel: "All Day Today")
        } else {
            updateStatusIcon(isOngoing: false)
            statusItem.button?.title = " No Upcoming Events"
            let noEventItem = NSMenuItem(title: "No upcoming events in the next 7 days", action: nil, keyEquivalent: "")
            noEventItem.isEnabled = false
            menu.addItem(noEventItem)
            menu.addItem(NSMenuItem.separator())
        }

        // Standard actions
        let openCalItem = NSMenuItem(title: "Open Calendar.app", action: #selector(openCalendarApp), keyEquivalent: "o")
        openCalItem.target = self
        menu.addItem(openCalItem)

        let refreshItem = NSMenuItem(title: "Refresh", action: #selector(updateNextEvent), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)

        let loginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        loginItem.target = self
        loginItem.state = isLaunchAtLoginEnabled() ? .on : .off
        menu.addItem(loginItem)

        menu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(title: "Quit CalendarBar", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    func truncate(_ string: String, limit: Int) -> String {
        if string.count <= limit { return string }
        return String(string.prefix(limit - 1)) + "…"
    }

    func buildEventDetailMenu(menu: NSMenu, event: EKEvent, statusLabel: String) {
        // Status header
        let statusItem = NSMenuItem(title: statusLabel, action: nil, keyEquivalent: "")
        statusItem.isEnabled = false
        menu.addItem(statusItem)

        // Event Title (bold)
        let title = event.title ?? "Untitled Event"
        let titleItem = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        let boldFont = NSFont.boldSystemFont(ofSize: 13)
        titleItem.attributedTitle = NSAttributedString(string: title, attributes: [.font: boldFont])
        menu.addItem(titleItem)

        // Time Range
        let tf = DateFormatter()
        tf.timeStyle = .short
        if event.isAllDay {
            let timeItem = NSMenuItem(title: "All Day", action: nil, keyEquivalent: "")
            timeItem.isEnabled = false
            menu.addItem(timeItem)
        } else {
            let timeStr = "\(tf.string(from: event.startDate)) – \(tf.string(from: event.endDate))"
            let timeItem = NSMenuItem(title: "Time: \(timeStr)", action: nil, keyEquivalent: "")
            timeItem.isEnabled = false
            menu.addItem(timeItem)
        }

        // Calendar Name
        if let calTitle = event.calendar?.title {
            let calItem = NSMenuItem(title: "Calendar: \(calTitle)", action: nil, keyEquivalent: "")
            calItem.isEnabled = false
            menu.addItem(calItem)
        }

        // Location
        if let loc = event.location, !loc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let locItem = NSMenuItem(title: "📍 \(loc)", action: nil, keyEquivalent: "")
            locItem.isEnabled = false
            menu.addItem(locItem)
        }

        // Meeting link detection (URL field or inside notes)
        if let meetingUrl = findMeetingURL(event: event) {
            let joinItem = NSMenuItem(title: "🔗 Join Meeting Link", action: #selector(openURLItem(_:)), keyEquivalent: "j")
            joinItem.target = self
            joinItem.representedObject = meetingUrl
            menu.addItem(joinItem)
        }

        menu.addItem(NSMenuItem.separator())
    }

    func findMeetingURL(event: EKEvent) -> URL? {
        if let url = event.url { return url }
        // Check notes or location for zoom/meet/teams/webex
        let text = (event.notes ?? "") + " " + (event.location ?? "")
        let patterns = [
            "https?://[a-zA-Z0-9.-]*zoom\\.us/j/[a-zA-Z0-9?=_&-]+",
            "https?://meet\\.google\\.com/[a-z]{3}-[a-z]{4}-[a-z]{3}",
            "https?://teams\\.microsoft\\.com/l/meetup-join/[a-zA-Z0-9?=_&%/-]+",
            "https?://[a-zA-Z0-9.-]*webex\\.com/[a-zA-Z0-9?=_&-]+"
        ]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range, in: text) {
                return URL(string: String(text[range]))
            }
        }
        return nil
    }

    @objc func openURLItem(_ sender: NSMenuItem) {
        if let url = sender.representedObject as? URL {
            NSWorkspace.shared.open(url)
        }
    }

    func isLaunchAtLoginEnabled() -> Bool {
        if #available(macOS 13.0, *) {
            if SMAppService.mainApp.status == .enabled {
                return true
            }
        }
        let script = "tell application \"System Events\" to return exists (login item \"CalendarBar\")"
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            let result = appleScript.executeAndReturnError(&error)
            return result.booleanValue
        }
        return false
    }

    @objc func toggleLaunchAtLogin() {
        let currentlyEnabled = isLaunchAtLoginEnabled()
        var handled = false

        if #available(macOS 13.0, *) {
            do {
                if currentlyEnabled {
                    try SMAppService.mainApp.unregister()
                } else {
                    try SMAppService.mainApp.register()
                }
                handled = true
            } catch {
                handled = false
            }
        }

        if !handled {
            let appPath = Bundle.main.bundlePath
            let script: String
            if currentlyEnabled {
                script = "tell application \"System Events\" to delete (every login item whose name is \"CalendarBar\")"
            } else {
                script = "tell application \"System Events\" to make login item at end with properties {name:\"CalendarBar\", path:\"\(appPath)\", hidden:false}"
            }
            if let appleScript = NSAppleScript(source: script) {
                var error: NSDictionary?
                appleScript.executeAndReturnError(&error)
            }
        }

        updateNextEvent()
    }

    @objc func openCalendarApp() {
        if let calUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.iCal") {
            NSWorkspace.shared.openApplication(at: calUrl, configuration: NSWorkspace.OpenConfiguration())
        }
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

// Main entry point
let app = NSApplication.shared
app.setActivationPolicy(.accessory) // Runs purely in the menu bar (no Dock icon)
let delegate = CalendarBarDelegate()
app.delegate = delegate
app.run()
