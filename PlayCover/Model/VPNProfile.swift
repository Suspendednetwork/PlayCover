//
//  VPNProfile.swift
//  PlayCover
//

import Foundation

// MARK: - VPN Backend

/// Controls which VPN binaries PlayCover will use when establishing a tunnel.
///
/// - `embedded`: Prefer binaries bundled inside the app's `Contents/Helpers/` directory.
///   Falls back to system-installed binaries when no bundled binary is present.
///   Use this mode to run VPN connections without requiring a separate Homebrew installation.
/// - `system`: Only search the standard system-wide paths written by Homebrew
///   (`/opt/homebrew/bin`, `/usr/local/bin`, `/usr/bin`).
enum VPNBackend: String, Codable, CaseIterable, Identifiable {
    /// Prefer the binary bundled inside `PlayCover.app/Contents/Helpers/`.
    case embedded
    /// Use only system-installed binaries (Homebrew / standard system locations).
    case system

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .embedded: return NSLocalizedString("vpn.backend.embedded", comment: "")
        case .system:   return NSLocalizedString("vpn.backend.system", comment: "")
        }
    }
}

// MARK: - VPN Profile Type

/// Supported VPN tunnel protocol types.
enum VPNType: String, Codable, CaseIterable, Identifiable {
    case openVPN = "OpenVPN"
    case wireGuard = "WireGuard"

    var id: String { rawValue }

    /// File extension used when storing the imported config on disk.
    var fileExtension: String {
        switch self {
        case .openVPN: return "ovpn"
        case .wireGuard: return "conf"
        }
    }
}

// MARK: - VPN Connection State

/// Observed connection state for a VPN profile.
enum VPNConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case disconnecting
    case failed(String)

    var localizedDescription: String {
        switch self {
        case .disconnected:
            return NSLocalizedString("vpn.state.disconnected", comment: "")
        case .connecting:
            return NSLocalizedString("vpn.state.connecting", comment: "")
        case .connected:
            return NSLocalizedString("vpn.state.connected", comment: "")
        case .disconnecting:
            return NSLocalizedString("vpn.state.disconnecting", comment: "")
        case .failed(let message):
            return String(format: NSLocalizedString("vpn.state.failed", comment: ""), message)
        }
    }

    var isActive: Bool {
        switch self {
        case .connecting, .connected, .disconnecting: return true
        default: return false
        }
    }
}

// MARK: - VPN Profile

/// A saved VPN profile that can be imported and managed by PlayCover.
struct VPNProfile: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var type: VPNType
    /// Name of the config file stored inside the VPN container directory.
    var configFileName: String
    var dateAdded: Date
    var lastConnected: Date?

    init(name: String, type: VPNType, configFileName: String) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.configFileName = configFileName
        self.dateAdded = Date()
    }

    // MARK: Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: VPNProfile, rhs: VPNProfile) -> Bool {
        lhs.id == rhs.id
    }
}
