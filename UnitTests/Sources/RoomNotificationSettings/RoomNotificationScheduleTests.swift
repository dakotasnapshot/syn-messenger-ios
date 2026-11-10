// SPDX-License-Identifier: AGPL-3.0-only

import SwiftUI
import Testing

#if canImport(ElementX)
@testable import ElementX
#else
@testable import ScheduleCore
#endif

struct RoomNotificationScheduleTests {
    private func schedule() -> RoomNotificationSchedule {
        var result = RoomNotificationSchedule()
        result.enabled = true
        result.timezone = "America/Chicago"
        return result
    }
    
    private func date(_ value: String) throws -> Date {
        try #require(ISO8601DateFormatter().date(from: value))
    }
    
    @Test(arguments: [
        ("2026-11-09T14:59:59Z", true),
        ("2026-11-09T15:00:00Z", false),
        ("2026-11-09T22:59:59Z", false),
        ("2026-11-09T23:00:00Z", true),
        ("2026-11-14T18:00:00Z", true)
    ])
    func daytimeBoundaries(value: (String, Bool)) throws {
        #expect(try schedule().mutes(at: date(value.0)) == value.1)
    }
    
    @Test(arguments: [
        ("2026-11-08T22:59:59Z", true),
        ("2026-11-09T00:00:00Z", false),
        ("2026-11-09T02:59:59Z", false),
        ("2026-11-09T03:00:00Z", true),
        ("2026-11-10T01:00:00Z", true)
    ])
    func sundayOvernight(value: (String, Bool)) throws {
        var subject = schedule()
        subject.timezone = "Etc/UTC"
        subject.days = [7]
        subject.startMinute = 23 * 60
        subject.endMinute = 3 * 60
        #expect(try subject.mutes(at: date(value.0)) == value.1)
    }
    
    @Test(arguments: ["2026-11-01T06:30:00Z", "2026-11-01T07:30:00Z"])
    func repeatedDSTHour(value: String) throws {
        var subject = schedule()
        subject.days = [7]
        subject.startMinute = 60
        subject.endMinute = 120
        #expect(try !subject.mutes(at: date(value)))
    }
    
    @Test(arguments: [("2026-03-08T07:59:59Z", false), ("2026-03-08T08:00:00Z", true)])
    func springDSTJump(value: (String, Bool)) throws {
        var subject = schedule()
        subject.days = [7]
        subject.startMinute = 60
        subject.endMinute = 180
        #expect(try subject.mutes(at: date(value.0)) == value.1)
    }
    
    @Test func explicitOverridesDoNotChangeHours() throws {
        var subject = schedule()
        let originalDays = subject.days
        subject.override = .normal
        #expect(try !subject.mutes(at: date("2026-11-14T18:00:00Z")))
        subject.override = .mute
        subject.enabled = false
        #expect(try subject.mutes(at: date("2026-11-09T18:00:00Z")))
        #expect(subject.days == originalDays)
        subject.override = .schedule
        #expect(try !subject.mutes(at: date("2026-11-09T18:00:00Z")))
    }
    
    @Test func macOSDocumentRoundTrip() throws {
        let data = Data(#"{"version":1,"enabled":true,"days":[1,2,3,4,5],"start_minute":540,"end_minute":1020,"timezone":"America/Chicago","override":"mute"}"#.utf8)
        let value = try JSONDecoder().decode(RoomNotificationSchedule.self, from: data)
        #expect(value.override == .mute)
        let encoded = try JSONEncoder().encode(value)
        #expect(try JSONDecoder().decode(RoomNotificationSchedule.self, from: encoded) == value)
        let object = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        #expect(object["start_minute"] as? Int == 540)
        #expect(object["startMinute"] == nil)
    }
    
    @Test func legacyMissingOverrideFollowsSchedule() throws {
        let data = Data(#"{"version":1,"enabled":true,"days":[1],"start_minute":540,"end_minute":1020,"timezone":"Etc/UTC"}"#.utf8)
        #expect(try JSONDecoder().decode(RoomNotificationSchedule.self, from: data).override == .schedule)
    }
    
    @Test(arguments: [
        #""version":2"#, #""days":[1,1]"#, #""days":[0]"#, #""days":[8]"#, #""days":[]"#,
        #""start_minute":-1"#, #""end_minute":1440"#, #""end_minute":540"#,
        #""timezone":"Not/AZone""#, #""override":"unexpected""#, #""override":null"#
    ])
    func invalidDocumentsRejected(replacement: String) throws {
        var object = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(schedule())) as? [String: Any])
        let changed = try #require(JSONSerialization.jsonObject(with: Data("{\(replacement)}".utf8)) as? [String: Any])
        object.merge(changed) { _, new in new }
        let data = try JSONSerialization.data(withJSONObject: object)
        #expect(throws: (any Error).self) { try JSONDecoder().decode(RoomNotificationSchedule.self, from: data) }
    }
    
    @Test func invalidDraftNeverMutesOrSaves() throws {
        var subject = schedule()
        subject.days = [99]
        subject.override = .mute
        #expect(!subject.mutes())
        #expect(throws: (any Error).self) {
            try RoomNotificationScheduleAPI.request(homeserver: "https://matrix.example", userID: "@alice:example", roomID: "!room:example", accessToken: "synthetic", saving: subject)
        }
    }
    
    @Test func accountDataRequestIsPerRoomAndAuthenticated() throws {
        let request = try RoomNotificationScheduleAPI.request(homeserver: "https://matrix.example/base", userID: "@alice:example", roomID: "!r/oom:#?%", accessToken: "synthetic", saving: schedule())
        let url = try #require(request.url)
        #expect(url.host == "matrix.example")
        #expect(url.query == nil)
        #expect(url.fragment == nil)
        #expect(url.absoluteString.contains("r%2Foom"))
        #expect(url.lastPathComponent == RoomNotificationSchedule.eventType)
        #expect(request.httpMethod == "PUT")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer synthetic")
        #expect(try JSONDecoder().decode(RoomNotificationSchedule.self, from: #require(request.httpBody)) == schedule())
    }
    
    @Test(arguments: [400, 401, 403, 404, 429, 500])
    func serverFailureNeverLooksLikeEmptySchedule(status: Int) throws {
        let url = try #require(URL(string: "https://matrix.example"))
        let response = try #require(HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil))
        #expect(throws: (any Error).self) {
            try RoomNotificationScheduleAPI.response(data: Data(#"{"errcode":"M_FORBIDDEN"}"#.utf8), response: response, saved: nil)
        }
    }
    
    @Test func missingScheduleAndSuccessfulSave() throws {
        let url = try #require(URL(string: "https://matrix.example"))
        let missing = try #require(HTTPURLResponse(url: url, statusCode: 404, httpVersion: nil, headerFields: nil))
        let result = try RoomNotificationScheduleAPI.response(data: Data(#"{"errcode":"M_NOT_FOUND"}"#.utf8), response: missing, saved: nil)
        #expect(result.supported)
        #expect(result.schedule == nil)
        let success = try #require(HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil))
        #expect(try RoomNotificationScheduleAPI.response(data: Data("{}".utf8), response: success, saved: schedule()).schedule == schedule())
        #expect(throws: (any Error).self) { try RoomNotificationScheduleAPI.response(data: Data("{}".utf8), response: success, saved: nil) }
    }
}
