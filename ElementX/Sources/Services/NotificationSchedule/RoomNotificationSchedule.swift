// SPDX-License-Identifier: AGPL-3.0-only

import SwiftUI

nonisolated struct RoomNotificationSchedule: Codable, Equatable, Sendable {
    static let eventType = "app.syn.notification_schedule"
    
    enum Override: String, Codable, CaseIterable, Sendable {
        case schedule
        case mute
        case normal
    }
    
    var version = 1
    var enabled = false
    var days = [1, 2, 3, 4, 5]
    var startMinute = 540
    var endMinute = 1020
    var timezone = TimeZone.current.identifier
    var override: Override = .schedule
    
    enum CodingKeys: String, CodingKey {
        case version, enabled, days, timezone, override
        case startMinute = "start_minute"
        case endMinute = "end_minute"
    }
    
    init() { }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        version = try values.decode(Int.self, forKey: .version)
        enabled = try values.decode(Bool.self, forKey: .enabled)
        days = try values.decode([Int].self, forKey: .days)
        startMinute = try values.decode(Int.self, forKey: .startMinute)
        endMinute = try values.decode(Int.self, forKey: .endMinute)
        timezone = try values.decode(String.self, forKey: .timezone)
        override = try values.contains(.override) ? values.decode(Override.self, forKey: .override) : .schedule
        guard isValid else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Invalid room notification schedule"))
        }
    }
    
    var isValid: Bool {
        version == 1 && days.count <= 7 && Set(days).count == days.count
            && days.allSatisfy { (1...7).contains($0) } && (!enabled || !days.isEmpty)
            && (0..<1440).contains(startMinute) && (0..<1440).contains(endMinute)
            && startMinute != endMinute && TimeZone(identifier: timezone) != nil
    }
    
    /// Evaluate wall-clock time at delivery, not through a background boundary timer.
    func mutes(at date: Date = .now) -> Bool {
        guard isValid else { return false }
        if override == .mute {
            return true
        }
        guard override == .schedule, enabled, let zone = TimeZone(identifier: timezone) else { return false }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        let components = calendar.dateComponents([.weekday, .hour, .minute], from: date)
        guard let weekday = components.weekday, let hour = components.hour, let minute = components.minute else { return false }
        let day = (weekday + 5) % 7 + 1
        let localMinute = hour * 60 + minute
        if startMinute < endMinute {
            return !(days.contains(day) && localMinute >= startMinute && localMinute < endMinute)
        }
        let previousDay = day == 1 ? 7 : day - 1
        return !((days.contains(day) && localMinute >= startMinute) || (days.contains(previousDay) && localMinute < endMinute))
    }
}

nonisolated struct RoomNotificationScheduleResponse: Codable, Sendable {
    var supported: Bool
    var schedule: RoomNotificationSchedule?
}
