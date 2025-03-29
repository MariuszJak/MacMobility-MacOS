//
//  ShortcutInstallView.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 29/03/2025.
//

import SwiftUI

struct ShortcutToInstall: Identifiable {
    let id: String = UUID().uuidString
    let name: String
    let description: String
    var isInstalled: Bool
}

class ShortcutInstallViewModel: ObservableObject {
    @Published var shortcuts: [ShortcutToInstall] = [
        .init(name: "Live Text Extractor", description: "Show and copy text found in any image via Live Text. The shortcut supports images passed via the share sheet, quick actions in Finder, or picking manually from Photos.", isInstalled: false),
        .init(name: "Show Clipboard", description: "Show the contents of the system clipboard. The shortcut can also show the type of the clipboard's contents, and it can run as a widget or Siri command.", isInstalled: false),
        .init(name: "Focus ON", description: "This shortcut will turn on focus mode.", isInstalled: false),
        .init(name: "Focus Off", description: "This shortcut will turn off focus mode allowing you to work on other applications.", isInstalled: false),
        .init(name: "PDF to Markdown", description: "Convert a PDF to Markdown and choose what to do with the resulting text document.", isInstalled: false),
        .init(name: "Upcoming Events", description: "This shortcut will show you a list of upcoming events in your calendar.", isInstalled: false),
        .init(name: "Convert to JPEG and Copy", description: "Convert any image previously copied to the clipboard to JPEG, stripping metadata from it. The converted image is copied to the clipboard, and you can optionally save it in the Photos app.", isInstalled: false),
        .init(name: "Calendar Locations", description: "Get a list of upcoming calendar events that contain locations.", isInstalled: false),
        .init(name: "Copy App Link", description: "Search for an app on the App Store, then copy its link to the system clipboard.", isInstalled: false),
        .init(name: "Copy Last Photo", description: "Copy the latest image from the Photos app to the clipboard.", isInstalled: false),
        .init(name: "Days Until...", description: "Calculate how many days are left until a date you can type in natural language. The shortcut was designed in English.", isInstalled: false),
        .init(name: "EXIF Inspector", description: "View EXIF metadata for a selected photo.", isInstalled: false),
        .init(name: "Get Image Resolution", description: "Get the resolution of any image passed as input. This shortcut supports images copied to the clipboard, the iOS and iPadOS share sheet, picking images from Files, or images selected in Finder on macOS. The shortcut can also run as a Quick Action on macOS.", isInstalled: false),
        .init(name: "Live Photo to GIF", description: "Convert a Live Photo to an animated GIF and preview it in Quick Look. The GIF can be saved to the Photos app directly from the preview.", isInstalled: false),
        .init(name: "ANC ON", description: "With this shortcut you can turn on the ANC", isInstalled: false),
        .init(name: "ANC OFF", description: "With this shortcut you can turn off the ANC", isInstalled: false),
        .init(name: "Pick Windows and Create Pairs", description: "Split the screen using two windows from currenly running apps. You can choose up to two windows from a list, so one will be resized to fill the left half of the screen, and the other will fill the right half.", isInstalled: false),
        .init(name: "Save App Store Icon", description: "Search the App Store for an app and save its icon to the Photos app.", isInstalled: false),
        .init(name: "Save App Store Screenshots", description: "Search the App Store for an app and save screenshots from the product page to the Photos app.", isInstalled: false),
        .init(name: "Take Screenshot and Share", description: "Take a screenshot and share it.", isInstalled: false),
        .init(name: "Weather for Upcoming Events", description: "Get the weather forecast for the location of an upcoming calendar event.", isInstalled: false),
        .init(name: "Word & Character Count", description: "Display a count of words and characters contained in the system clipboard.", isInstalled: false)
    ]
    private var timer: Timer?
    
    init() {
        updateInstallationInfo()
        startMonitoring()
    }
    
    func installShortcut(named shortcutFileName: String) {
        guard let shortcutURL = Bundle.main.url(forResource: shortcutFileName, withExtension: "shortcut") else {
            print("Shortcut file not found")
            return
        }
        
        NSWorkspace.shared.open(shortcutURL)
    }
    
    func getShortcutsList() -> [String] {
        let process = Process()
        let pipe = Pipe()
        
        process.launchPath = "/usr/bin/shortcuts"
        process.arguments = ["list"]
        process.standardOutput = pipe
        
        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)
            let list = output?.components(separatedBy: "\n")
                .filter { !$0.isEmpty }
            
            return list ?? []
        } catch {
            print("Failed to fetch shortcuts: \(error)")
            return []
        }
    }
    
    func updateInstallationInfo() {
        let installedShortcuts = getShortcutsList()
        shortcuts.enumerated().forEach { index, item in
            shortcuts[index].isInstalled = installedShortcuts.contains(item.name)
        }
    }
    
    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            self?.updateInstallationInfo()
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}

struct ShortcutInstallView: View {
    @ObservedObject private var viewModel = ShortcutInstallViewModel()
    
    var body: some View {
        VStack {
            Text("Install Shortcuts")
                .font(.system(size: 21, weight: .bold))
                .padding(.bottom, 18.0)
            Divider()
            ScrollView {
                ForEach(viewModel.shortcuts) { shortcut in
                    InstallShortcutView(shortcut: shortcut) {
                        viewModel.installShortcut(named: shortcut.name)
                    }
                }
            }
        }
        .padding()
    }
}

struct InstallShortcutView: View {
    let shortcut: ShortcutToInstall
    let action: () -> Void
    
    var body: some View {
        VStack {
            HStack {
                VStack {
                    Spacer()
                    Image(.shortcuts)
                        .resizable()
                        .frame(width: 128, height: 128)
                        .cornerRadius(20)
                    Spacer()
                }
                .padding(.trailing, 21.0)
                VStack(alignment: .leading) {
                    Spacer()
                    Text(shortcut.name)
                        .font(.system(size: 17, weight: .bold))
                        .padding(.bottom, 4.0)
                    Text(shortcut.description)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.gray)
                        .padding(.bottom, 8.0)
                    Button(shortcut.isInstalled ? "Installed" : "Install Now") {
                        action()
                    }
                    .disabled(shortcut.isInstalled)
                    Spacer()
                }
                Spacer()
            }
        }
    }
}
