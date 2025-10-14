//
//  SettingsView.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 12/10/2025.
//

import Foundation
import SwiftUI
import Combine

enum SettingsSection: String, CaseIterable, Identifiable {
    case general = "General"
    case permissions = "Permissions"
    case privacy = "Privacy"
    
    var id: String { rawValue }
}

struct SettingsView: View {
    @State private var selectedSection: SettingsSection = .general
    var connectionManager: ConnectionManager
    
    init(connectionManager: ConnectionManager) {
        self.connectionManager = connectionManager
    }
    
    var body: some View {
        HStack(spacing: 0) {
            List(SettingsSection.allCases, selection: $selectedSection) { section in
                Label(section.rawValue, systemImage: icon(for: section))
                    .tag(section)
            }
            .listStyle(SidebarListStyle())
            .frame(minWidth: 180, maxWidth: 220)
            .padding(.vertical)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 16) {
                switch selectedSection {
                case .general:
                    GeneralSettingsView()
                case .permissions:
                    PermissionView(viewModel: .init(connectionManager: connectionManager))
                case .privacy:
                    PrivacySettingsView()
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 600, height: 400)
    }
    
    private func icon(for section: SettingsSection) -> String {
        switch section {
        case .general: return "gearshape"
        case .permissions: return "lock.shield"
        case .privacy: return "hand.raised"
        }
    }
}

// MARK: - Individual Sections

class GeneralSettingsViewModel: ObservableObject {
    @Published var browser: Browsers
    @Published var editorWindowOnStart: Bool
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        browser = UserDefaults.standard.get(key: .browser) ?? .chrome
        editorWindowOnStart = UserDefaults.standard.get(key: .shouldOpenEditorWindowOnAppLaunch) ?? true
        binding()
    }
    
    private func binding() {
        $browser
            .receive(on: DispatchQueue.main)
            .sink { browser in
                UserDefaults.standard.store(browser, for: .browser)
            }
            .store(in: &cancellables)
        
        $editorWindowOnStart
            .receive(on: DispatchQueue.main)
            .sink { editorWindowOnStart in
                UserDefaults.standard.store(editorWindowOnStart, for: .shouldOpenEditorWindowOnAppLaunch)
            }
            .store(in: &cancellables)
    }
}

struct GeneralSettingsView: View {
    @StateObject private var manager = LaunchAtLoginManager()
    @ObservedObject private var viewModel = GeneralSettingsViewModel()
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("General Settings")
                    .font(.title2)
                    .bold()
                Toggle(isOn: Binding(
                    get: { manager.isEnabled },
                    set: { _ in manager.toggle() }
                )) {
                    Text("Launch at login")
                    Text("Launch app on system startup.")
                        .font(.system(size: 11, weight: .light))
                        .foregroundStyle(Color.gray)
                }
//                Toggle("Open Editor window on application start", isOn: $viewModel.editorWindowOnStart)
                Divider()
                Picker("Browser", selection: $viewModel.browser) {
                    Text("Chrome").tag(Browsers.chrome)
                    Text("Safari").tag(Browsers.safari)
                    Text("Orion").tag(Browsers.orion)
                }
                .pickerStyle(.menu)
                Text("Select default browser for creating and opening links. IMPORTANT: This setting will not affect existing links. You have to manually update them if needed.")
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(Color.gray)
            }
            .padding()
            Spacer()
        }
    }
}

class PrivacySettingsViewModel: ObservableObject {
    @Published var isSendingUsageData: Bool = false
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        isSendingUsageData = UserDefaults.standard.get(key: .analyticsConsent) ?? false
        self.binding()
    }
    
    private func binding() {
        $isSendingUsageData
            .receive(on: DispatchQueue.main)
            .sink { analyticsConsent in
                UserDefaults.standard.store(analyticsConsent, for: .analyticsConsent)
            }
            .store(in: &cancellables)
    }
}

struct PrivacySettingsView: View {
    @ObservedObject var viewModel = PrivacySettingsViewModel()
    private let alignment: HorizontalAlignment
    
    init(alignment: HorizontalAlignment = .leading) {
        self.alignment = alignment
    }
    
    var body: some View {
        HStack {
            VStack(alignment: alignment, spacing: 12) {
                Text("Privacy Settings")
                    .font(.title2)
                    .bold()
                Toggle("Allow analytics tracking", isOn: $viewModel.isSendingUsageData)
                Text("We’d like to collect anonymous analytics data to improve app performance and user experience. No personal data is ever shared.")
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(Color.gray)
            }
            .padding()
            Spacer()
        }
    }
}

@MainActor
final class LaunchAtLoginManager: ObservableObject {
    @Published var isEnabled: Bool = false

    private let label = "com.macmobility.MacMobility-MacOS.launcher"
    private let appExecutableName = Bundle.main.infoDictionary?["CFBundleExecutable"] as? String ?? ""
    private var appExecPath: String {
        "\(Bundle.main.bundlePath)/Contents/MacOS/\(appExecutableName)"
    }

    private var agentPlistPath: String {
        ("~/Library/LaunchAgents/\(label).plist" as NSString).expandingTildeInPath
    }

    init() {
        refreshStatus()
    }

    func refreshStatus() {
        // Consider both file existence and launchctl list presence if needed.
        isEnabled = FileManager.default.fileExists(atPath: agentPlistPath)
    }

    func toggle() {
        if isEnabled { disableLaunchAtLogin() }
        else { enableLaunchAtLogin() }
    }

    private func enableLaunchAtLogin() {
        let plist = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key><string>\(label)</string>
            <key>ProgramArguments</key>
            <array>
                <string>\(appExecPath)</string>
            </array>
            <key>RunAtLoad</key><true/>
            <key>KeepAlive</key><false/>
        </dict>
        </plist>
        """

        do {
            try plist.write(toFile: agentPlistPath, atomically: true, encoding: .utf8)
            refreshStatus()
        } catch {
            print("⚠️ Failed to write LaunchAgent plist: \(error)")
        }
    }

    private func disableLaunchAtLogin() {
        // Try to unload (best-effort) then remove the file.
        try? runLaunchctl(arguments: ["unload", agentPlistPath])
        do {
            if FileManager.default.fileExists(atPath: agentPlistPath) {
                try FileManager.default.removeItem(atPath: agentPlistPath)
            }
            refreshStatus()
        } catch {
            print("⚠️ Failed to remove LaunchAgent plist: \(error)")
        }
    }

    private func runLaunchctl(arguments: [String]) throws {
        let task = Process()
        task.launchPath = "/bin/launchctl"
        task.arguments = arguments
        try task.run()
        task.waitUntilExit()
    }
}
