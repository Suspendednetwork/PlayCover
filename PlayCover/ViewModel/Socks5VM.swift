//
//  Socks5VM.swift
//  PlayCover
//

import Foundation

// MARK: - SOCKS5 ViewModel

/// Manages the global SOCKS5 proxy configuration, persisting it to `UserDefaults`.
class Socks5VM: ObservableObject {

    // MARK: Singleton

    static let shared = Socks5VM()

    // MARK: Published State

    /// Whether the global SOCKS5 proxy is enabled.
    @Published var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: Socks5VM.enabledKey) }
    }

    /// The current proxy configuration.
    @Published var config: Socks5Config {
        didSet { saveConfig() }
    }

    // MARK: UserDefaults Keys

    private static let enabledKey = "socks5.enabled"
    private static let configKey  = "socks5.config"

    // MARK: Init

    private init() {
        isEnabled = UserDefaults.standard.bool(forKey: Socks5VM.enabledKey)
        config = Self.loadConfig()
    }

    // MARK: Helpers

    /// Returns the `ALL_PROXY` value when the proxy is enabled and configured, otherwise `nil`.
    var activeProxyURL: String? {
        guard isEnabled else { return nil }
        return config.proxyURLString
    }

    // MARK: Persistence

    private static func loadConfig() -> Socks5Config {
        guard let data = UserDefaults.standard.data(forKey: configKey),
              let decoded = try? JSONDecoder().decode(Socks5Config.self, from: data) else {
            return Socks5Config()
        }
        return decoded
    }

    private func saveConfig() {
        guard let data = try? JSONEncoder().encode(config) else { return }
        UserDefaults.standard.set(data, forKey: Socks5VM.configKey)
    }
}
