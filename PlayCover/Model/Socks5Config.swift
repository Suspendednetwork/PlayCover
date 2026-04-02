//
//  Socks5Config.swift
//  PlayCover
//

import Foundation

// MARK: - SOCKS5 Configuration

/// Global SOCKS5 proxy configuration persisted by `Socks5VM`.
struct Socks5Config: Codable, Equatable {
    var host: String = ""
    var port: UInt16 = 1080
    var requiresAuth: Bool = false
    var username: String = ""
    var password: String = ""

    /// Returns `true` when the configuration has a non-empty host.
    var isConfigured: Bool { !host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    /// A `socks5://` URL string suitable for the `ALL_PROXY` environment variable.
    /// Returns `nil` when the host is empty or the config is invalid.
    var proxyURLString: String? {
        let trimmedHost = host.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedHost.isEmpty, port > 0 else { return nil }

        if requiresAuth {
            let encodedUser = username.addingPercentEncoding(withAllowedCharacters: .urlUserAllowed) ?? username
            let encodedPass = password.addingPercentEncoding(withAllowedCharacters: .urlPasswordAllowed) ?? password
            return "socks5://\(encodedUser):\(encodedPass)@\(trimmedHost):\(port)"
        }
        return "socks5://\(trimmedHost):\(port)"
    }
}
