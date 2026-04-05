#!/usr/bin/env swift

import Foundation
import EventKit

// MARK: - Configuration

struct Config {
    let startDate: Date
    let endDate: Date
    let outputDir: String
    let excludedCalendars: [String]
    let vaultPath: String
}

// MARK: - Calendar Event

struct CalendarEvent {
    let startDate: Date
    let endDate: Date
    let title: String
    let notes: String?
    let calendarTitle: String
    let isAllDay: Bool
}

// MARK: - Date Utilities

extension Date {
    var startOfWeek: Date {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: self)

        // weekday: 1=Sunday, 2=Monday, 3=Tuesday, 4=Wednesday, 5=Thursday, 6=Friday, 7=Saturday
        // To get Monday, subtract (weekday - 2) days, but handle Sunday (weekday=1) specially
        let daysToSubtract: Int
        switch weekday {
        case 1: // Sunday - go back 6 days to get to previous Monday
            daysToSubtract = 6
        default: // 2-7 - subtract (weekday - 2) to get to Monday
            daysToSubtract = weekday - 2
        }
        let weekStart = calendar.date(byAdding: .day, value: -daysToSubtract, to: self)!
        // Normalize to start of day for consistent dictionary keys
        return calendar.startOfDay(for: weekStart)
    }

    var endOfWeek: Date {
        let calendar = Calendar.current
        let start = startOfWeek
        return calendar.date(byAdding: .day, value: 6, to: start)!
    }

    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }

    func formattedDateWithWeekday() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let weekdayFormatter = DateFormatter()
        weekdayFormatter.dateFormat = "EEEE"
        weekdayFormatter.locale = Locale(identifier: "zh_CN")

        let weekdays = ["", "周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: self)
        return "\(formattedDate()) (\(weekdays[weekday]))"
    }

    func formattedTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: self)
    }

    func hoursBetween(_ otherDate: Date) -> Double {
        let interval = self.timeIntervalSince(otherDate)
        return abs(interval / 3600)
    }

    func getWeekString(for weekIndex: Int) -> String {
        let calendar = Calendar.current

        // Get the Monday of the week
        let monday = startOfWeek
        let year = calendar.component(.year, from: monday)
        let month = calendar.component(.month, from: monday)

        // Calculate which week of the month this Monday is in
        // Get the first day of the month
        let components = calendar.dateComponents([.year, .month], from: monday)
        let firstOfMonth = calendar.date(from: components)!

        // Get the weekday of the first day of the month (1=Sunday, 7=Saturday)
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)

        // Adjust to Monday (2 is Monday)
        var firstMondayOffset: Int
        if firstWeekday == 1 {
            // First day is Sunday, first Monday is day 2
            firstMondayOffset = 1
        } else {
            // First Monday is at 9 - firstWeekday
            firstMondayOffset = 9 - firstWeekday
        }

        // Calculate days between Monday of this week and first Monday of the month
        let daysSinceFirstMonday = calendar.dateComponents([.day], from: firstOfMonth, to: monday).day! + firstMondayOffset - 1

        // Calculate week number (1-based)
        let weekOfMonth = max(1, (daysSinceFirstMonday / 7) + 1)

        return "\(String(format: "%04d", year))-\(String(format: "%02d", month))-week\(weekOfMonth)"
    }
}

// MARK: - String Utilities

extension String {
    var sanitizedForFilename: String {
        return self
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
    }

    func escapedForYAML() -> String {
        return self
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
    }

    func emojiForCalendar() -> String {
        if contains("充电游乐场") { return "🔋" }
        if contains("Operating System") || contains("OS") { return "👿" }
        if contains("Reading") || contains("Study") || contains("PKM") { return "📚" }
        if contains("多巴胺") { return "🎮" }
        if contains("必要时间") || contains("Meals") || contains("Care") { return "⚡" }
        if contains("Planning") { return "📝" }
        if contains("工作") { return "💼" }
        if contains("Foundation") { return "🏗️" }
        if contains("Growth") { return "📈" }
        return "📅"
    }
}

// MARK: - Main Class

class CalendarExporter {
    private let eventStore: EKEventStore
    private let config: Config

    init(config: Config) {
        self.config = config
        self.eventStore = EKEventStore()
    }

    // Request calendar access permission
    func requestAccess(completion: @escaping (Bool) -> Void) {
        eventStore.requestAccess(to: .event) { granted, error in
            if let error = error {
                print("❌ Error requesting access: \(error.localizedDescription)")
                completion(false)
                return
            }
            completion(granted)
        }
    }

    // Fetch events from calendar
    func fetchEvents() -> [CalendarEvent] {
        let calendars = eventStore.calendars(for: .event)

        // Filter calendars - use contains matching (excludes calendars containing the excluded keywords)
        let validCalendars = calendars.filter { calendar in
            let title = calendar.title
            for excluded in config.excludedCalendars {
                if title.contains(excluded) {
                    return false
                }
            }
            return true
        }

        let excludedTitles = calendars.filter { calendar in
            let title = calendar.title
            for excluded in config.excludedCalendars {
                if title.contains(excluded) {
                    return true
                }
            }
            return false
        }.map { $0.title }

        print("🚫 Excluded calendars: \(excludedTitles.joined(separator: ", "))")
        print("📅 Valid calendars: \(validCalendars.count)")

        // Fetch events that either start OR end within the date range
        // We need a wider range to capture cross-day events
        let calendar = Calendar.current
        let extendedStart = calendar.date(byAdding: .day, value: -2, to: config.startDate)!
        let extendedEnd = calendar.date(byAdding: .day, value: 2, to: config.endDate)!

        let predicate = eventStore.predicateForEvents(withStart: extendedStart,
                                                        end: extendedEnd,
                                                        calendars: validCalendars)
        let events = eventStore.events(matching: predicate).sorted { $0.startDate < $1.startDate }

        // Filter to only include events that have any overlap with our target date range
        let cal = Calendar.current
        let rangeStart = cal.startOfDay(for: config.startDate)
        let rangeEnd = cal.date(byAdding: .day, value: 1, to: rangeStart)! // end of day

        return events.compactMap { event in
            // Check if event overlaps with our date range
            guard let eventStart = event.startDate,
                  let eventEnd = event.endDate else {
                return nil
            }

            // Event overlaps if: event starts before end of range AND event ends after start of range
            let overlaps = eventStart < rangeEnd && eventEnd > rangeStart

            if !overlaps {
                return nil
            }

            // Handle optional title and notes
            let title = event.title ?? "无标题"
            let notes = event.notes

            return CalendarEvent(
                startDate: eventStart,
                endDate: eventEnd,
                title: title,
                notes: notes,
                calendarTitle: event.calendar.title,
                isAllDay: event.isAllDay
            )
        }
    }

    // Group events by week
    func groupEventsByWeek(_ events: [CalendarEvent]) -> [Date: [CalendarEvent]] {
        var grouped: [Date: [CalendarEvent]] = [:]

        for event in events {
            let calendar = Calendar.current

            // For all-day events, use startDate (macOS stores them with extended endDate)
            // For cross-day events, use endDate (where the main activity happens)
            var eventDate: Date
            if event.isAllDay {
                eventDate = event.startDate
            } else if calendar.isDate(event.startDate, inSameDayAs: event.endDate) {
                eventDate = event.startDate
            } else {
                // Cross-day event: use end date
                eventDate = event.endDate
            }

            let weekStart = eventDate.startOfWeek
            if grouped[weekStart] == nil {
                grouped[weekStart] = []
            }
            grouped[weekStart]?.append(event)
        }

        return grouped
    }

    // Group events by day
    func groupEventsByDay(_ events: [CalendarEvent]) -> [Date: [CalendarEvent]] {
        var grouped: [Date: [CalendarEvent]] = [:]
        let calendar = Calendar.current

        for event in events {
            // For cross-day events, group by end date (where the main activity happens)
            // If event spans multiple days, use the date with more hours
            var groupingDate = event.startDate
            if calendar.isDate(event.startDate, inSameDayAs: event.endDate) {
                groupingDate = event.startDate
            } else {
                // Cross-day event: group by end date if event spans midnight
                let startHour = calendar.component(.hour, from: event.startDate)
                if startHour < 12 {
                    // Events starting before noon and ending next day should be grouped by start date
                    groupingDate = event.startDate
                } else {
                    // Events starting in evening and ending next day should be grouped by end date
                    groupingDate = event.endDate
                }
            }

            let day = calendar.startOfDay(for: groupingDate)
            if grouped[day] == nil {
                grouped[day] = []
            }
            grouped[day]?.append(event)
        }

        return grouped
    }

    // Generate markdown for a single event
    func generateEventMarkdown(_ event: CalendarEvent) -> String {
        var markdown = ""

        let isCrossDay = !event.isAllDay && event.startDate.formattedDate() != event.endDate.formattedDate()
        let calendarEmoji = event.calendarTitle.emojiForCalendar()

        // Handle cross-day events (like sleep) with special format
        if isCrossDay {
            markdown += "### 😴 昨日延续：\(event.title)\n"
            markdown += "---\n"
            markdown += "入睡时间: \(event.startDate.formattedTime())\n"
            markdown += "起床时间: \(event.endDate.formattedTime())\n"
            let hours = event.endDate.hoursBetween(event.startDate)
            markdown += "睡眠时长: \(String(format: "%.1f", hours))\n"
        } else if event.isAllDay {
            markdown += "### 📅 全天 \(event.title)\n"
            markdown += "---\n"
            markdown += "duration: 全天\n"
            markdown += "分类：\(event.calendarTitle.escapedForYAML())\n"
            if let notes = event.notes, !notes.isEmpty {
                markdown += "备注：\(notes.escapedForYAML())\n"
            }
        } else {
            markdown += "### \(event.startDate.formattedTime()) - \(event.endDate.formattedTime()) \(calendarEmoji) \(event.title)\n"
            markdown += "---\n"
            markdown += "start: \(event.startDate.formattedTime())\n"
            markdown += "end: \(event.endDate.formattedTime())\n"
            markdown += "分类：\(event.calendarTitle.escapedForYAML())\n"
            if let notes = event.notes, !notes.isEmpty {
                markdown += "备注：\(notes.escapedForYAML())\n"
            }
        }

        return markdown
    }

    // Generate markdown for a single day
    func generateDayMarkdown(_ date: Date, events: [CalendarEvent]) -> String {
        var markdown = "---\n"
        markdown += "type: daily_schedule\n"
        markdown += "date: \(date.formattedDate())\n"
        markdown += "weekday: \(date.formattedDateWithWeekday())\n"
        markdown += "events: \(events.count)\n"
        markdown += "---\n"

        // Calculate time distribution
        let calendar = Calendar.current
        var morningHours = 0.0
        var afternoonHours = 0.0
        var eveningHours = 0.0

        for event in events {
            if event.isAllDay { continue }
            if event.startDate.formattedDate() != event.endDate.formattedDate() { continue } // Skip cross-day

            let startHour = calendar.component(.hour, from: event.startDate)
            let duration = event.endDate.hoursBetween(event.startDate)

            if startHour < 12 {
                morningHours += duration
            } else if startHour < 18 {
                afternoonHours += duration
            } else {
                eveningHours += duration
            }
        }

        // Add time distribution
        markdown += "⏰ 时间分布：上午 \(String(format: "%.1f", morningHours))h | 下午 \(String(format: "%.1f", afternoonHours))h | 晚上 \(String(format: "%.1f", eveningHours))h\n\n"

        for event in events {
            markdown += generateEventMarkdown(event)
        }

        return markdown
    }

    // Generate markdown for a week
    func generateWeekMarkdown(_ weekStart: Date, events: [CalendarEvent], weekIndex: Int) -> String {
        let weekEnd = weekStart.endOfWeek
        let weekString = weekStart.getWeekString(for: weekIndex)

        var markdown = "---\n"
        markdown += "type: weekly_schedule\n"
        markdown += "week: \(weekString)\n"
        markdown += "date_range: \(weekStart.formattedDate()) ~ \(weekEnd.formattedDate())\n"
        markdown += "---\n"

        let eventsByDay = groupEventsByDay(events)
        let sortedDays = eventsByDay.keys.sorted()

        for day in sortedDays {
            if let dayEvents = eventsByDay[day] {
                markdown += generateDayMarkdown(day, events: dayEvents)
            }
        }

        return markdown
    }

    // Write markdown to file
    func writeToFile(_ markdown: String, filename: String, date: Date) throws {
        // Determine output directory based on year
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)

        var outputPath: String
        if year == 2026 {
            // 2026年 documents go to "daily schedule/2026年/"
            outputPath = (config.vaultPath as NSString).appendingPathComponent(config.outputDir)
            outputPath = (outputPath as NSString).appendingPathComponent("2026年")
        } else {
            // Other years go to "daily schedule/"
            outputPath = (config.vaultPath as NSString).appendingPathComponent(config.outputDir)
        }

        let fullPath = (outputPath as NSString).appendingPathComponent("\(filename).md")

        // Ensure output directory exists
        try FileManager.default.createDirectory(atPath: outputPath,
                                                withIntermediateDirectories: true,
                                                attributes: nil)

        try markdown.write(toFile: fullPath, atomically: true, encoding: .utf8)
        print("✅ Wrote: \(fullPath)")
    }

    // Run export
    func run() {
        requestAccess { [weak self] granted in
            guard let self = self else { return }

            guard granted else {
                print("❌ Calendar access denied. Please grant permission in System Settings > Privacy & Security > Calendars.")
                exit(1)
            }

            print("📅 Fetching events from \(self.config.startDate.formattedDate()) to \(self.config.endDate.formattedDate())...")

            let events = self.fetchEvents()
            print("✅ Found \(events.count) events")

            let eventsByDay = self.groupEventsByDay(events)

            // Write each day to its own file
            for (date, dayEvents) in eventsByDay.sorted(by: { $0.key < $1.key }) {
                if !dayEvents.isEmpty {
                    let markdown = self.generateDayMarkdown(date, events: dayEvents)
                    do {
                        let filename = date.formattedDate()
                        print("📝 Writing \(filename).md with \(dayEvents.count) events")
                        try self.writeToFile(markdown, filename: filename, date: date)
                    } catch {
                        print("❌ Error writing file: \(error.localizedDescription)")
                    }
                }
            }

            print("🎉 Export completed!")
            exit(0)
        }

        // Keep the script running
        RunLoop.main.run()
    }
}

// MARK: - Command Line Parsing

func parseArguments() -> Config {
    let arguments = CommandLine.arguments
    let calendar = Calendar.current

    // Default: start from today
    let defaultStart = calendar.startOfDay(for: Date())
    let defaultEnd = defaultStart

    var startDate = defaultStart
    var endDate = defaultEnd
    var outputDir = "daily schedule"
    var excludedCalendars = ["节假日", "计划的提醒事项"]

    // Parse arguments
    var i = 1
    while i < arguments.count {
        switch arguments[i] {
        case "--start-date":
            if i + 1 < arguments.count {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                if let date = formatter.date(from: arguments[i + 1]) {
                    startDate = date
                } else {
                    print("⚠️ Invalid start date format, using default")
                }
                i += 1
            }
        case "--end-date":
            if i + 1 < arguments.count {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                if let date = formatter.date(from: arguments[i + 1]) {
                    endDate = date
                } else {
                    print("⚠️ Invalid end date format, using default")
                }
                i += 1
            }
        case "--output-dir":
            if i + 1 < arguments.count {
                outputDir = arguments[i + 1]
                i += 1
            }
        case "--exclude":
            if i + 1 < arguments.count {
                excludedCalendars = arguments[i + 1].split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
                i += 1
            }
        default:
            break
        }
        i += 1
    }

    // Get vault path - hardcoded to the Obsidian vault location
    // The script is at: vault/.obsidian/skills/calendar-export/
    let scriptPath = (CommandLine.arguments[0] as NSString).expandingTildeInPath
    let scriptDir = FileManager.default.currentDirectoryPath

    // Calculate vault path: script directory should be vault/.obsidian/skills/calendar-export
    var vaultPath = (scriptDir as NSString).deletingLastPathComponent // calendar-export
    vaultPath = (vaultPath as NSString).deletingLastPathComponent // skills
    vaultPath = (vaultPath as NSString).deletingLastPathComponent // .obsidian

    print("📂 Script path: \(scriptPath)")
    print("📂 Script dir: \(scriptDir)")
    print("📂 Vault path: \(vaultPath)")

    return Config(
        startDate: startDate,
        endDate: endDate,
        outputDir: outputDir,
        excludedCalendars: excludedCalendars,
        vaultPath: vaultPath
    )
}

// MARK: - Entry Point

let config = parseArguments()
print("🚀 Calendar Export started")
print("📂 Output directory: \(config.outputDir)")
print("🚫 Excluded calendars: \(config.excludedCalendars.joined(separator: ", "))")

let exporter = CalendarExporter(config: config)
exporter.run()
