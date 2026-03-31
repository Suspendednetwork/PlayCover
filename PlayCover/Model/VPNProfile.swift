//
//  VPNProfile.swift
//  PlayCover
//

import Foundation

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
