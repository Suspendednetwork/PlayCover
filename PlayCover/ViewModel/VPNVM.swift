//
//  VPNVM.swift
//  PlayCover
//

import Foundation

// MARK: - VPN ViewModel

/// Manages VPN profile storage, import, and connection lifecycle.
class VPNVM: ObservableObject {

    // MARK: Singleton

    static let shared = VPNVM()

    // MARK: Published State

    @Published var profiles: [VPNProfile] = []
    @Published var activeProfileID: UUID?
    @Published var connectionState: VPNConnectionState = .disconnected
    @Published var connectionLog: String = ""

    // MARK: Private Properties

    private var metadataURL: URL
    /// Path to the OpenVPN PID file written by `--writepid`.
    private var openvpnPIDPath: String {
        NSTemporaryDirectory() + "playcover-openvpn.pid"
    }
    /// Path to the OpenVPN daemon log file.
    private var openvpnLogPath: String {
        NSTemporaryDirectory() + "playcover-openvpn.log"
    }
    /// Timer used to poll the OpenVPN log file after starting the daemon.
    private var openvpnPollTimer: Timer?

    // MARK: VPN Container Directory

    /// Root directory where all VPN configs are stored.
    static var vpnContainerURL: URL {
        let url = PlayTools.playCoverContainer
            .appendingPathComponent("VPN")
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url,
                                                     withIntermediateDirectories: true)
        }
        return url
    }

    // MARK: Init

    private init() {
        metadataURL = Self.vpnContainerURL
            .appendingPathComponent("profiles")
            .appendingPathExtension("json")
        load()
    }

    // MARK: Persistence

    /// Persist profile list to disk.
    private func save() {
        do {
            let data = try JSONEncoder().encode(profiles)
            try data.write(to: metadataURL, options: .atomic)
        } catch {
            Log.shared.error(error)
        }
    }

    /// Load profile list from disk.
    private func load() {
        guard FileManager.default.fileExists(atPath: metadataURL.path),
              let data = try? Data(contentsOf: metadataURL),
              let decoded = try? JSONDecoder().decode([VPNProfile].self, from: data) else {
            return
        }
        profiles = decoded
    }

    // MARK: Config File URL

    func configURL(for profile: VPNProfile) -> URL {
        Self.vpnContainerURL.appendingPathComponent(profile.configFileName)
    }

    // MARK: Import

    /// Import a VPN config file. Copies it into the VPN container and registers a profile.
    /// - Parameters:
    ///   - sourceURL: URL of the config file chosen by the user.
    ///   - type: The VPN protocol type.
    ///   - name: Human-readable name for the profile.
    func importProfile(from sourceURL: URL, type: VPNType, name: String) {
        let sanitised = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sanitised.isEmpty else {
            Log.shared.error(VPNError.emptyName)
            return
        }

        let fileName = "\(UUID().uuidString).\(type.fileExtension)"
        let destURL = Self.vpnContainerURL.appendingPathComponent(fileName)

        do {
            // If the file is security-scoped (e.g. from open panel), start access.
            let secured = sourceURL.startAccessingSecurityScopedResource()
            defer { if secured { sourceURL.stopAccessingSecurityScopedResource() } }

            try FileManager.default.copyItem(at: sourceURL, to: destURL)
            // Restrict permissions: only the owner may read/write the config.
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: destURL.path)
        } catch {
            Log.shared.error(error)
            return
        }

        let profile = VPNProfile(name: sanitised, type: type, configFileName: fileName)
        Task { @MainActor in
            self.profiles.append(profile)
            self.save()
        }
    }

    // MARK: Delete

    /// Remove a profile and its config file from disk.
    func delete(profile: VPNProfile) {
        if activeProfileID == profile.id {
            disconnect()
        }
        let url = configURL(for: profile)
        try? FileManager.default.removeItem(at: url)
        Task { @MainActor in
            self.profiles.removeAll { $0.id == profile.id }
            self.save()
        }
    }

    // MARK: Connect / Disconnect

    /// Attempt to connect the given profile.
    func connect(profile: VPNProfile) {
        guard connectionState == .disconnected else { return }

        let cfgURL = configURL(for: profile)
        guard FileManager.default.fileExists(atPath: cfgURL.path) else {
            reportError(NSLocalizedString("vpn.error.configNotFound", comment: ""))
            return
        }

        switch profile.type {
        case .wireGuard:
            connectWireGuard(profile: profile, configURL: cfgURL)
        case .openVPN:
            connectOpenVPN(profile: profile, configURL: cfgURL)
        }
    }

    /// Disconnect the currently active VPN connection.
    func disconnect() {
        guard let id = activeProfileID,
              let profile = profiles.first(where: { $0.id == id }) else {
            resetState()
            return
        }

        connectionState = .disconnecting

        switch profile.type {
        case .wireGuard:
            disconnectWireGuard(profile: profile)
        case .openVPN:
            disconnectOpenVPN()
        }
    }

    // MARK: WireGuard

    private func connectWireGuard(profile: VPNProfile, configURL: URL) {
        guard let wgQuick = findExecutable(names: [
            "/opt/homebrew/bin/wg-quick",
            "/usr/local/bin/wg-quick",
            "/usr/bin/wg-quick"
        ]) else {
            reportError(NSLocalizedString("vpn.error.wgNotFound", comment: ""))
            return
        }

        // wg-quick derives the interface name from the config file name (without extension).
        // For disconnect / retry we pass the full config path so wg-quick resolves the
        // interface name the same way it did on connect, avoiding UUID-length name issues.
        connectionState = .connecting
        activeProfileID = profile.id
        connectionLog = ""

        runPrivileged(binary: wgQuick, args: ["up", configURL.path]) { [weak self] success, output in
            guard let self else { return }
            if success {
                Task { @MainActor in
                    self.connectionState = .connected
                    self.markLastConnected(profileID: profile.id)
                    self.connectionLog = output
                }
            } else if output.contains("already exists") {
                // Interface already up — bring it down then back up.
                self.runPrivileged(binary: wgQuick, args: ["down", configURL.path]) { _, _ in
                    self.runPrivileged(binary: wgQuick, args: ["up", configURL.path]) { success2, output2 in
                        Task { @MainActor in
                            if success2 {
                                self.connectionState = .connected
                                self.markLastConnected(profileID: profile.id)
                            } else {
                                self.reportError(output2)
                            }
                            self.connectionLog = output2
                        }
                    }
                }
            } else {
                Task { @MainActor in
                    self.reportError(output)
                    self.connectionLog = output
                }
            }
        }
    }

    private func disconnectWireGuard(profile: VPNProfile) {
        guard let wgQuick = findExecutable(names: [
            "/opt/homebrew/bin/wg-quick",
            "/usr/local/bin/wg-quick",
            "/usr/bin/wg-quick"
        ]) else {
            resetState()
            return
        }

        let cfgURL = configURL(for: profile)

        runPrivileged(binary: wgQuick, args: ["down", cfgURL.path]) { [weak self] _, _ in
            Task { @MainActor in
                self?.resetState()
            }
        }
    }

    // MARK: OpenVPN

    private func connectOpenVPN(profile: VPNProfile, configURL: URL) {
        guard let ovpnBin = findExecutable(names: [
            "/opt/homebrew/bin/openvpn",
            "/usr/local/bin/openvpn",
            "/usr/bin/openvpn"
        ]) else {
            reportError(NSLocalizedString("vpn.error.ovpnNotFound", comment: ""))
            return
        }

        connectionState = .connecting
        activeProfileID = profile.id
        connectionLog = ""

        // Clear stale log and PID files.
        try? "".write(toFile: openvpnLogPath, atomically: true, encoding: .utf8)
        try? FileManager.default.removeItem(atPath: openvpnPIDPath)

        // Launch OpenVPN as a daemon so `do shell script` returns immediately.
        runPrivileged(binary: ovpnBin,
                      args: ["--config", configURL.path,
                             "--daemon",
                             "--log", openvpnLogPath,
                             "--writepid", openvpnPIDPath]) { [weak self] success, output in
            guard let self else { return }
            if success {
                self.startOpenVPNLogPolling(profileID: profile.id)
            } else {
                Task { @MainActor in
                    self.reportError(output)
                    self.connectionLog = output
                }
            }
        }
    }

    /// Poll the OpenVPN log file until a connection success/failure string appears.
    private func startOpenVPNLogPolling(profileID: UUID) {
        var elapsed = 0
        let timeout = 60

        DispatchQueue.main.async {
            self.openvpnPollTimer?.invalidate()
            self.openvpnPollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
                guard let self else { timer.invalidate(); return }
                elapsed += 1

                let content = (try? String(contentsOfFile: self.openvpnLogPath)) ?? ""

                Task { @MainActor in
                    self.connectionLog = content

                    if content.contains("Initialization Sequence Completed") {
                        timer.invalidate()
                        self.connectionState = .connected
                        self.markLastConnected(profileID: profileID)
                    } else if content.contains("AUTH_FAILED") {
                        timer.invalidate()
                        self.reportError(NSLocalizedString("vpn.error.authFailed", comment: ""))
                    } else if content.contains("TLS Error") || content.contains("TLS handshake failed") {
                        timer.invalidate()
                        self.reportError(NSLocalizedString("vpn.error.tlsFailed", comment: ""))
                    } else if elapsed >= timeout {
                        timer.invalidate()
                        self.reportError(NSLocalizedString("vpn.error.timeout", comment: ""))
                    }
                }
            }
        }
    }

    private func disconnectOpenVPN() {
        openvpnPollTimer?.invalidate()
        openvpnPollTimer = nil

        guard let pidStr = try? String(contentsOfFile: openvpnPIDPath, encoding: .utf8),
              let pid = Int(pidStr.trimmingCharacters(in: .whitespacesAndNewlines)),
              pid > 0 else {
            resetState()
            return
        }

        runPrivileged(binary: "/bin/kill", args: [String(pid)]) { [weak self] _, _ in
            Task { @MainActor in
                self?.resetState()
            }
        }
    }

    // MARK: Privileged Execution

    /// Run a binary with administrator privileges using AppleScript.
    ///
    /// - Note: The binary path and each argument are individually single-quote–escaped
    ///   before being passed to `do shell script`. User-supplied data in the config
    ///   *file path* is safe because PlayCover generates UUID-based filenames.
    private func runPrivileged(binary: String,
                               args: [String],
                               completion: @escaping (Bool, String) -> Void) {
        func singleQuote(_ state: String) -> String {
            "'" + state.replacingOccurrences(of: "'", with: "'\\''") + "'"
        }
        let cmd = ([binary] + args).map(singleQuote).joined(separator: " ")
        // Escape any double-quotes and backslashes that would break the AppleScript literal.
        let escaped = cmd
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let script = "do shell script \"\(escaped)\" with administrator privileges"

        DispatchQueue.global(qos: .userInitiated).async {
            var error: NSDictionary?
            let appleScript = NSAppleScript(source: script)
            let result = appleScript?.executeAndReturnError(&error)

            if let error = error {
                completion(false, error.description)
            } else {
                completion(true, result?.stringValue ?? "")
            }
        }
    }

    // MARK: Helpers

    /// Return the first path in `names` that exists, is executable, and begins with
    /// a known system prefix. The prefix check guards against symlink/path confusion
    /// if one of the expected directories is writable by an attacker.
    private func findExecutable(names: [String]) -> String? {
        let allowedPrefixes = ["/opt/homebrew/", "/usr/local/", "/usr/bin/", "/bin/"]
        return names.first { path in
            FileManager.default.isExecutableFile(atPath: path) &&
            allowedPrefixes.contains(where: { path.hasPrefix($0) })
        }
    }

    /// Reset published state back to disconnected. Must be called on the main thread.
    private func resetState() {
        connectionState = .disconnected
        activeProfileID = nil
    }

    /// Set a failed state and log the message. Must be called on the main thread.
    private func reportError(_ message: String) {
        connectionState = .failed(message)
        activeProfileID = nil
        Log.shared.log(message, isError: true)
    }

    @MainActor
    private func markLastConnected(profileID: UUID) {
        if let index = profiles.firstIndex(where: { $0.id == profileID }) {
            profiles[index].lastConnected = Date()
            save()
        }
    }
}

// MARK: - VPN Errors

enum VPNError: LocalizedError {
    case emptyName
    case configNotFound

    var errorDescription: String? {
        switch self {
        case .emptyName:
            return NSLocalizedString("vpn.error.emptyName", comment: "")
        case .configNotFound:
            return NSLocalizedString("vpn.error.configNotFound", comment: "")
        }
    }
}
