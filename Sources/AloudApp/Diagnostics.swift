//
//  Diagnostics.swift
//  Aloud
//
//  Created by Zain Najam on 09/09/2026.
//  Copyright © 2026 Zain Najam. All rights reserved.
//

import Foundation
import os

/// A log that survives the app quitting.
///
/// A menu bar app has nowhere to show what went wrong. When the shortcut does not fire
/// there is no window, no error and nothing to read, which is exactly the position this
/// project was in when the shortcut turned out to be Raycast's. One file, appended to, is
/// the difference between diagnosing that in a minute and guessing at it.
public enum Diagnostics {

    private static let logger = Logger(subsystem: "com.zainnajamkhan.aloud", category: "app")

    private static let fileURL: URL? = {
        guard let logs = try? FileManager.default.url(
            for: .libraryDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        ) else { return nil }
        let directory = logs.appendingPathComponent("Logs/Aloud", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("aloud.log")
    }()

    private static let formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]
        return formatter
    }()

    public static func log(_ message: String) {
        logger.log("\(message, privacy: .public)")

        guard let fileURL else { return }
        let line = "\(formatter.string(from: Date()))  \(message)\n"
        guard let data = line.data(using: .utf8) else { return }

        if let handle = try? FileHandle(forWritingTo: fileURL) {
            defer { try? handle.close() }
            _ = try? handle.seekToEnd()
            try? handle.write(contentsOf: data)
        } else {
            try? data.write(to: fileURL)
        }
    }

    /// Where to look, printed so it can be pasted into a support mail.
    public static var path: String { fileURL?.path ?? "unavailable" }
}
