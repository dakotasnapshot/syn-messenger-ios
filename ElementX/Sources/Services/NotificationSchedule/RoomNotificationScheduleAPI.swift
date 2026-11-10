// SPDX-License-Identifier: AGPL-3.0-only

import SwiftUI

nonisolated enum RoomNotificationScheduleAPI {
    enum RequestError: Error {
        case invalidURL
        case invalidSchedule
        case serverResponse
    }
    
    static func request(homeserver: String, userID: String, roomID: String, accessToken: String,
                        saving schedule: RoomNotificationSchedule?) throws -> URLRequest {
        guard !userID.isEmpty, !roomID.isEmpty,
              var url = URL(string: homeserver), url.scheme == "https" || url.scheme == "http", url.host != nil else {
            throw RequestError.invalidURL
        }
        for component in ["_matrix", "client", "v3", "user", userID, "rooms", roomID, "account_data", RoomNotificationSchedule.eventType] {
            url.append(component: component)
        }
        var request = URLRequest(url: url, timeoutInterval: 10)
        request.httpMethod = schedule == nil ? "GET" : "PUT"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        if let schedule {
            guard schedule.isValid else { throw RequestError.invalidSchedule }
            request.httpBody = try JSONEncoder().encode(schedule)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return request
    }
    
    static func response(data: Data, response: URLResponse, saved schedule: RoomNotificationSchedule?) throws -> RoomNotificationScheduleResponse {
        guard let response = response as? HTTPURLResponse else { throw RequestError.serverResponse }
        if schedule == nil, response.statusCode == 404,
           let error = try? JSONDecoder().decode(MatrixError.self, from: data), error.errcode == "M_NOT_FOUND" {
            return .init(supported: true, schedule: nil)
        }
        guard (200..<300).contains(response.statusCode) else { throw RequestError.serverResponse }
        if let schedule {
            return .init(supported: true, schedule: schedule)
        }
        return try .init(supported: true, schedule: JSONDecoder().decode(RoomNotificationSchedule.self, from: data))
    }
    
    private struct MatrixError: Decodable {
        let errcode: String
    }
}
