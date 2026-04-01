//
//  VPNSettings.swift
//  PlayCover
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - VPN Settings View

struct VPNSettings: View {
    // @ObservedObject (not @StateObject) because VPNVM.shared is a pre-existing singleton.
    @ObservedObject private var vpnVM = VPNVM.shared

    // macOS List(selection:) requires the binding to match the element's ID type (UUID).
    @State private var selectedProfileID: UUID?
    /// Derived from the selected row ID; nil when nothing is selected or the profile was deleted.
    private var selectedProfile: VPNProfile? {
        guard let selectedProfileID else { return nil }
        return vpnVM.profiles.first(where: { $0.id == selectedProfileID })
    }

    @State private var showingImportSheet = false
    @State private var importType: VPNType = .wireGuard

    @State private var showingDeleteAlert = false
    @State private var profileToDelete: VPNProfile?

    @State private var showingLogSheet = false

    /// Persisted VPN backend preference.
    @AppStorage("vpnBackend") private var vpnBackend: String = VPNBackend.embedded.rawValue

    var body: some View {
        VStack(spacing: 0) {
            profileListSection
            Divider()
            backendSection
            Divider()
            statusBar
        }
        .frame(width: 600, height: 390)
        .sheet(isPresented: $showingImportSheet) {
            ImportVPNProfileView(vpnType: importType)
        }
        .sheet(isPresented: $showingLogSheet) {
            VPNLogView(log: vpnVM.connectionLog)
        }
        .alert(
            String(format: NSLocalizedString("vpn.delete.confirm", comment: ""), profileToDelete?.name ?? ""),
            isPresented: $showingDeleteAlert
        ) {
            Button(NSLocalizedString("button.Cancel", comment: ""), role: .cancel) {}
            Button(NSLocalizedString("vpn.button.delete", comment: ""), role: .destructive) {
                if let profile = profileToDelete {
                    vpnVM.delete(profile: profile)
                    if selectedProfileID == profile.id {
                        selectedProfileID = nil
                    }
                }
            }
        }
    }

    private var profileListSection: some View {
        HStack(alignment: .top, spacing: 0) {
            // Profile list
            List(vpnVM.profiles, id: \.id, selection: $selectedProfileID) { profile in
                VPNProfileRow(profile: profile,
                              isActive: vpnVM.activeProfileID == profile.id,
                              connectionState: vpnVM.connectionState)
            }
            .listStyle(.bordered(alternatesRowBackgrounds: true))

            VStack(spacing: 8) {
                Menu {
                    Button {
                        importType = .wireGuard
                        showingImportSheet = true
                    } label: {
                        Label("WireGuard (.conf)", systemImage: "shield")
                    }

                    Button {
                        importType = .openVPN
                        showingImportSheet = true
                    } label: {
                        Label("OpenVPN (.ovpn)", systemImage: "network")
                    }
                } label: {
                    Text("vpn.button.import")
                        .frame(width: 140)
                }
                .menuStyle(.borderedButton)

                Button {
                    guard let profile = selectedProfile else { return }
                    profileToDelete = profile
                    showingDeleteAlert = true
                } label: {
                    Text("vpn.button.delete")
                        .frame(width: 140)
                }
                .disabled(selectedProfile == nil)

                Divider()

                if vpnVM.connectionState == .disconnected {
                    Button {
                        guard let profile = selectedProfile else { return }
                        vpnVM.connect(profile: profile)
                    } label: {
                        Text("vpn.button.connect")
                            .frame(width: 140)
                    }
                    .disabled(selectedProfile == nil)
                } else {
                    Button {
                        vpnVM.disconnect()
                    } label: {
                        Text("vpn.button.disconnect")
                            .frame(width: 140)
                    }
                    .disabled(vpnVM.connectionState == .disconnecting)
                }

                Button {
                    showingLogSheet = true
                } label: {
                    Text("vpn.button.viewLog")
                        .frame(width: 140)
                }
                .disabled(vpnVM.connectionLog.isEmpty)

                Spacer()
            }
            .padding(.leading, 12)
            .padding(.top, 4)
        }
        .padding(16)
    }

    private var backendSection: some View {
        HStack(spacing: 8) {
            Text("vpn.backend.label")
                .font(.callout)
                .foregroundStyle(.secondary)

            Picker("", selection: $vpnBackend) {
                ForEach(VPNBackend.allCases) { backend in
                    Text(backend.localizedName).tag(backend.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 320)
            .help(NSLocalizedString("vpn.backend.help", comment: ""))

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var statusBar: some View {
        HStack(spacing: 8) {
            connectionIndicator
                .frame(width: 10, height: 10)

            Text(vpnVM.connectionState.localizedDescription)
                .font(.callout)
                .foregroundStyle(.secondary)

            Spacer()

            if let profile = vpnVM.profiles.first(where: { $0.id == vpnVM.activeProfileID }) {
                Text(profile.name)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.bar)
    }

    @ViewBuilder
    private var connectionIndicator: some View {
        switch vpnVM.connectionState {
        case .connected:
            Circle().fill(Color.green)
        case .connecting, .disconnecting:
            Circle().fill(Color.yellow)
        case .failed:
            Circle().fill(Color.red)
        default:
            Circle().fill(Color.gray.opacity(0.5))
        }
    }
}

// MARK: - Profile Row

private struct VPNProfileRow: View {
    let profile: VPNProfile
    let isActive: Bool
    let connectionState: VPNConnectionState

    var body: some View {
        HStack {
            Image(systemName: typeIcon)
                .foregroundStyle(isActive ? .green : .secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(profile.name)
                    .fontWeight(isActive ? .semibold : .regular)

                HStack(spacing: 4) {
                    Text(profile.type.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let last = profile.lastConnected {
                        Text("·")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(last, style: .relative)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            if isActive {
                statusBadge
            }
        }
        .padding(.vertical, 2)
    }

    private var typeIcon: String {
        switch profile.type {
        case .wireGuard: return "shield.lefthalf.filled"
        case .openVPN: return "network"
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch connectionState {
        case .connecting, .disconnecting:
            ProgressView().controlSize(.small)
        case .connected:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .failed:
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.red)
        default:
            EmptyView()
        }
    }
}

// MARK: - Import VPN Profile Sheet

struct ImportVPNProfileView: View {
    let vpnType: VPNType

    @State private var profileName = ""
    @State private var selectedFileURL: URL?
    @State private var showingFilePicker = false

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var vpnVM = VPNVM.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(String(format: NSLocalizedString("vpn.import.title", comment: ""), vpnType.rawValue))
                .font(.headline)

            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("vpn.import.name")
                    .frame(width: 120, alignment: .leading)

                TextField(NSLocalizedString("vpn.import.namePlaceholder", comment: ""), text: $profileName)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 300)

                Spacer()
            }

            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("vpn.import.file")
                    .frame(width: 120, alignment: .leading)

                HStack {
                    Text(selectedFileURL?.lastPathComponent ?? NSLocalizedString("vpn.import.noFile", comment: ""))
                        .foregroundStyle(selectedFileURL == nil ? .secondary : .primary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: 220, alignment: .leading)

                    Button(NSLocalizedString("vpn.import.browse", comment: "")) {
                        showingFilePicker = true
                    }
                }

                Spacer()
            }

            Spacer()

            HStack {
                Spacer()
                Button(NSLocalizedString("button.Cancel", comment: "")) {
                    dismiss()
                }
                Button(NSLocalizedString("button.OK", comment: "")) {
                    if let url = selectedFileURL {
                        let name = profileName.isEmpty ? url.deletingPathExtension().lastPathComponent : profileName
                        vpnVM.importProfile(from: url, type: vpnType, name: name)
                    }
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(selectedFileURL == nil)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 480, height: 200)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: allowedContentTypes,
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                selectedFileURL = url
                if profileName.isEmpty {
                    profileName = url.deletingPathExtension().lastPathComponent
                }
            case .failure(let error):
                Log.shared.error(error)
            }
        }
    }

    private var allowedContentTypes: [UTType] {
        var types: [UTType] = [.plainText, .data]
        if let custom = UTType(filenameExtension: vpnType.fileExtension) {
            types.insert(custom, at: 0)
        }
        return types
    }
}

// MARK: - VPN Log Viewer

struct VPNLogView: View {
    let log: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("vpn.log.title")
                .font(.headline)

            ScrollView {
                Text(log.isEmpty ? NSLocalizedString("vpn.log.empty", comment: "") : log)
                    .font(.system(.caption, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(nsColor: .textBackgroundColor))
            .cornerRadius(6)

            HStack {
                Spacer()
                Button(NSLocalizedString("button.OK", comment: "")) {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 560, height: 340)
    }
}

// MARK: - Preview

#Preview {
    VPNSettings()
}
