//
// Copyright 2026 SYN Messenger contributors.
//
// SPDX-License-Identifier: AGPL-3.0-only
//

import CryptoKit
import SwiftUI

enum SYNRoomWallpaperStore {
    enum Preset: String, CaseIterable, Identifiable {
        case conversations, connections, signal
        
        var id: String {
            rawValue
        }
        
        var title: String {
            rawValue.capitalized
        }
        
        var symbol: String {
            switch self {
            case .conversations: "bubble.left.and.bubble.right.fill"
            case .connections: "person.2.fill"
            case .signal: "wave.3.right"
            }
        }
    }
    
    static let didChange = Notification.Name("SYNRoomWallpaperDidChange")
    
    static func image(roomID: String) -> UIImage? {
        if let rawValue = UserDefaults.standard.string(forKey: presetKey(roomID: roomID)),
           let preset = Preset(rawValue: rawValue) {
            return image(for: preset)
        }
        guard let data = try? Data(contentsOf: url(roomID: roomID)) else { return nil }
        return UIImage(data: data)
    }
    
    static func preset(roomID: String) -> Preset? {
        UserDefaults.standard.string(forKey: presetKey(roomID: roomID)).flatMap(Preset.init(rawValue:))
    }
    
    static func select(_ preset: Preset, roomID: String) {
        UserDefaults.standard.set(preset.rawValue, forKey: presetKey(roomID: roomID))
        NotificationCenter.default.post(name: didChange, object: roomID)
    }
    
    static func save(_ data: Data, roomID: String) throws {
        guard let image = UIImage(data: data), let jpeg = image.jpegData(compressionQuality: 0.86) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let destination = url(roomID: roomID)
        try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
        try jpeg.write(to: destination, options: .atomic)
        UserDefaults.standard.removeObject(forKey: presetKey(roomID: roomID))
        NotificationCenter.default.post(name: didChange, object: roomID)
    }
    
    static func remove(roomID: String) throws {
        let destination = url(roomID: roomID)
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        UserDefaults.standard.removeObject(forKey: presetKey(roomID: roomID))
        NotificationCenter.default.post(name: didChange, object: roomID)
    }
    
    private static func url(roomID: String) -> URL {
        let digest = SHA256.hash(data: Data(roomID.utf8)).map { String(format: "%02x", $0) }.joined()
        return URL.applicationSupportDirectory.appending(path: "RoomWallpapers/").appending(path: "\(digest).jpg")
    }
    
    private static func presetKey(roomID: String) -> String {
        "syn.room-wallpaper.preset.\(SHA256.hash(data: Data(roomID.utf8)).description)"
    }
    
    private static func image(for preset: Preset) -> UIImage {
        let size = CGSize(width: 900, height: 1600)
        return UIGraphicsImageRenderer(size: size).image { context in
            UIColor(red: 0.025, green: 0.025, blue: 0.035, alpha: 1).setFill()
            context.cgContext.fill(CGRect(origin: .zero, size: size))
            let config = UIImage.SymbolConfiguration(pointSize: 44, weight: .light)
            let symbol = UIImage(systemName: preset.symbol, withConfiguration: config)?
                .withTintColor(UIColor(white: preset == .signal ? 0.32 : 0.22, alpha: 0.55), renderingMode: .alwaysOriginal)
            for row in 0..<18 {
                for column in 0..<9 where (row + column) % 2 == 0 {
                    let x = CGFloat(column) * 115 - (row.isMultiple(of: 2) ? 35 : 85)
                    let y = CGFloat(row) * 100 - 30
                    symbol?.draw(at: CGPoint(x: x, y: y))
                }
            }
        }
    }
}
