//
//  AppIntegrity.swift
//  PlayCover
//

import Foundation
import AppKit

@MainActor
final class AppIntegrity: ObservableObject {
    /// When true, MainView shows the "Move to Applications folder?" alert.
    @Published var integrityOff: Bool = false

    init() {
        verify()
    }

    func verify() {
        integrityOff = !Self.isInAllowedApplicationsFolder()
    }

    func moveToApps() {
        do {
            let fileManager = FileManager.default

            let sourceAppURL = Bundle.main.bundleURL.resolvingSymlinksInPath()

            // Move to per-user Applications folder (~/Applications)
            let userApplicationsURL = fileManager.homeDirectoryForCurrentUser
                .appendingPathComponent("Applications", isDirectory: true)

            // Ensure ~/Applications exists
            try fileManager.createDirectory(
                at: userApplicationsURL,
                withIntermediateDirectories: true,
                attributes: nil
            )

            let destinationAppURL = userApplicationsURL
                .appendingPathComponent(sourceAppURL.lastPathComponent, isDirectory: true)

            // If already there, just relaunch
            if sourceAppURL.standardizedFileURL == destinationAppURL.standardizedFileURL {
                relaunch(from: destinationAppURL)
                return
            }

            // If an app already exists at destination, remove it first
            if fileManager.fileExists(atPath: destinationAppURL.path) {
                try fileManager.removeItem(at: destinationAppURL)
            }

            // Prefer move; if move fails (different volume), fall back to copy+remove
            do {
                try fileManager.moveItem(at: sourceAppURL, to: destinationAppURL)
            } catch {
                try fileManager.copyItem(at: sourceAppURL, to: destinationAppURL)
                try fileManager.removeItem(at: sourceAppURL)
            }

            relaunch(from: destinationAppURL)
        } catch {
            Log.shared.error(error)
        }
    }

    private func relaunch(from appURL: URL) {
        // Launch the app at the new location
        NSWorkspace.shared.openApplication(at: appURL, configuration: NSWorkspace.OpenConfiguration())

        // Quit current instance
        NSApp.terminate(nil)
    }

    private static func isInAllowedApplicationsFolder() -> Bool {
        let appURL = Bundle.main.bundleURL.resolvingSymlinksInPath()

        let systemApplicationsURL = URL(fileURLWithPath: "/Applications", isDirectory: true).resolvingSymlinksInPath()

        let userApplicationsURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Applications", isDirectory: true)
            .resolvingSymlinksInPath()

        // Accept either /Applications/PlayCover.app or ~/Applications/PlayCover.app
        return appURL.path.hasPrefix(systemApplicationsURL.path + "/")
            || appURL.path.hasPrefix(userApplicationsURL.path + "/")
    }
}
