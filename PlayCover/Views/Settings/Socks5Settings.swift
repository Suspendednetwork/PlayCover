//
//  Socks5Settings.swift
//  PlayCover
//

import SwiftUI

// MARK: - Global SOCKS5 Settings View

struct Socks5SettingsView: View {
    @ObservedObject var vm: Socks5VM

    @State private var host: String = ""
    @State private var portText: String = ""
    @State private var requiresAuth: Bool = false
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            formSection
            Divider()
            statusBar
        }
        .frame(width: 500, height: 300)
        .onAppear(perform: populateFields)
    }

    // MARK: - Form Section

    private var formSection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Toggle("socks5.enable", isOn: $vm.isEnabled)
                    .help("socks5.enable.help")
                    .padding(.bottom, 4)

                Divider()

                Group {
                    hostPortRow
                    authToggleRow
                    if requiresAuth {
                        credentialsRows
                    }
                }
                .disabled(!vm.isEnabled)

                Spacer(minLength: 0)
            }
            .padding(20)
        }
    }

    private var hostPortRow: some View {
        HStack(spacing: 12) {
            Text("socks5.host")
                .frame(width: 90, alignment: .leading)
            TextField(NSLocalizedString("socks5.host.placeholder", comment: ""), text: $host)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: .infinity)
                .onChange(of: host) { _ in commitFields() }

            Text("socks5.port")
                .frame(width: 30, alignment: .leading)
            TextField("1080", text: $portText)
                .textFieldStyle(.roundedBorder)
                .frame(width: 70)
                .onChange(of: portText) { _ in commitFields() }
        }
    }

    private var authToggleRow: some View {
        HStack {
            Toggle("socks5.requiresAuth", isOn: $requiresAuth)
                .onChange(of: requiresAuth) { _ in commitFields() }
            Spacer()
        }
    }

    private var credentialsRows: some View {
        Group {
            HStack(spacing: 12) {
                Text("socks5.username")
                    .frame(width: 90, alignment: .leading)
                TextField(NSLocalizedString("socks5.username.placeholder", comment: ""), text: $username)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: username) { _ in commitFields() }
            }
            HStack(spacing: 12) {
                Text("socks5.password")
                    .frame(width: 90, alignment: .leading)
                if showPassword {
                    TextField(NSLocalizedString("socks5.password.placeholder", comment: ""), text: $password)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: password) { _ in commitFields() }
                } else {
                    SecureField(NSLocalizedString("socks5.password.placeholder", comment: ""), text: $password)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: password) { _ in commitFields() }
                }
                Button {
                    showPassword.toggle()
                } label: {
                    Image(systemName: showPassword ? "eye.slash" : "eye")
                }
                .buttonStyle(.plain)
                .help(showPassword ? NSLocalizedString("socks5.password.hide", comment: "")
                                   : NSLocalizedString("socks5.password.show", comment: ""))
            }
        }
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)

            Text(statusText)
                .font(.callout)
                .foregroundStyle(.secondary)

            Spacer()

            if let url = vm.activeProxyURL {
                Text(url)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private var statusColor: Color {
        guard vm.isEnabled else { return Color.gray.opacity(0.5) }
        return vm.config.isConfigured ? .green : .yellow
    }

    private var statusText: String {
        guard vm.isEnabled else {
            return NSLocalizedString("socks5.status.disabled", comment: "")
        }
        return vm.config.isConfigured
            ? NSLocalizedString("socks5.status.configured", comment: "")
            : NSLocalizedString("socks5.status.noHost", comment: "")
    }

    // MARK: - Helpers

    private func populateFields() {
        host        = vm.config.host
        portText    = String(vm.config.port)
        requiresAuth = vm.config.requiresAuth
        username    = vm.config.username
        password    = vm.config.password
    }

    private func commitFields() {
        let port = UInt16(portText) ?? 1080
        vm.config = Socks5Config(
            host: host,
            port: port,
            requiresAuth: requiresAuth,
            username: username,
            password: password
        )
    }
}

// MARK: - Preview

#Preview {
    Socks5SettingsView(vm: Socks5VM.shared)
}
