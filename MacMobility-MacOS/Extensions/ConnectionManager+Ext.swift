//
//  ConnectionManager+Ext.swift
//  MacMobility-MacOS
//
//  Created by CoderBlocks on 07/03/2025.
//

import Foundation
import MultipeerConnectivity
import os
import Combine
import AppKit
import SwiftUI

protocol ConnectionManagerWorskpaceCapable {
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID)
    func openApp(at path: String)
    func mainDisplayID() -> CGDirectDisplayID
    func moveCursor(onDisplay display: CGDirectDisplayID, toPoint point: CGPoint)
    func processWorkspace(_ workspace: WorkspaceItem, completion: @escaping () -> Void)
    func processApp(_ app: AppInfo, size: CGSize, position: CGPoint, completion: @escaping () -> Void)
    func resizeAppWindow(appName: String, width: CGFloat, height: CGFloat, screenPosition: CGPoint)
    func moveToNextWorkspace()
    func getFrameOfScreen() -> NSRect?
}

extension ConnectionManager {
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let shortcutItem = try? JSONDecoder().decode(ShortcutObject.self, from: data) {
            DispatchQueue.main.async {
                self.runShortuct(for: shortcutItem)
            }
            return
        }
        if let string = String(data: data, encoding: .utf8) {
            if string == "Connected - send data." {
                let diff = self.shortcuts.difference(from: [])
                self.send(shortcutsDiff: handleDiff(diff))
            } else {
                focusToApp(string)
            }
        }
    }
    
    func runShortuct(for shortcutItem: ShortcutObject) {
        switch shortcutItem.type {
        case .app:
            openApp(at: shortcutItem.path ?? "")
        case .shortcut:
            openShortcut(name: shortcutItem.title)
        case .webpage:
            openWebPage(for: shortcutItem)
        case .utility:
            switch shortcutItem.utilityType {
            case .commandline:
                if let script = shortcutItem.scriptCode {
                    if script.contains("macbook://extend-display") {
                        NotificationCenter.default.post(
                            name: .extendScreen,
                            object: nil,
                            userInfo: nil
                        )
                        return
                    }
                    if script.contains("raycast://") {
                        if let url = URL(string: script) {
                            NSWorkspace.shared.open(url)
                        }
                        return
                    }
                    if script.contains("FILE_CONVERTER") {
                        let input = script.split(separator: ",")[1]
                        let output = script.split(separator: ",")[2]
                        convertSelectedFiles(from: String(input), to: String(output))
                        return
                    }
                    if let message = runInlineBashScript(script: script), message.lowercased().contains("error") {
                        DispatchQueue.main.async {
                            self.localError = message
                            self.showsLocalError = true
                        }
                    }
                }
            case .multiselection:
                runMultiselection(for: shortcutItem)
            case .automation:
                self.dynamicUrls.1.removeAll()
                if shortcutItem.scriptCode == "GET SAFARI URLs" {
                    let safariURLs = getURLs(from: .safari)
                    if !safariURLs.isEmpty {
                        DispatchQueue.main.async {
                            self.dynamicUrls = (.safari, safariURLs)
                        }
                    }
                    return
                } else if shortcutItem.scriptCode == "GET CHROME URLs" {
                    let chromeWebsites = getURLs(from: .chrome)
                    if !chromeWebsites.isEmpty {
                        DispatchQueue.main.async {
                            self.dynamicUrls = (.chrome, chromeWebsites)
                        }
                    }
                    return
                } else if shortcutItem.scriptCode == "GET ORION URLs" {
                    let orionWebsites = getURLs(from: .orion)
                    if !orionWebsites.isEmpty {
                        DispatchQueue.main.async {
                            self.dynamicUrls = (.orion, orionWebsites)
                        }
                    }
                    return
                }
                if let script = shortcutItem.scriptCode {
                    execute(script) { error in
                        if error.description.lowercased().contains("error") {
                            self.localError = error.description
                            self.showsLocalError = true
                        }
                    }
                }
            case .macro:
                if let script = shortcutItem.scriptCode {
                    keyRecorder.recordedKeys = script.split(separator: ",").map { .init(key: $0.base) }
                    keyRecorder.playMacro()
                }
            case .none:
                break
            @unknown default:
                break
            }
        }
    }
    
    func getURLs(from browser: Browsers) -> [String] {
        let script = """
        set urlList to ""
        tell application "\(browser.name)"
            repeat with w in windows
                repeat with t in tabs of w
                    set urlList to urlList & (URL of t) & linefeed
                end repeat
            end repeat
        end tell
        return urlList
        """
        
        let process = Process()
        process.launchPath = "/usr/bin/osascript"
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        process.arguments = ["-e", script]
        
        do {
            try process.run()
        } catch {
            print("Failed to run script:", error)
            return []
        }
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        
        guard let output = String(data: data, encoding: .utf8) else {
            print("Failed to read output")
            return []
        }
        
        let urls = output
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        return urls
    }
    
    func runMultiselection(for item: ShortcutObject) {
        if let tools = item.objects {
            tools.forEach { tool in
                switch tool.type {
                case .app:
                    openApp(at: tool.path ?? "")
                case .shortcut:
                    openShortcut(name: tool.title)
                case .webpage:
                    openWebPage(for: tool)
                case .utility:
                    switch tool.utilityType {
                    case .commandline:
                        if let script = tool.scriptCode {
                            if script.contains("macbook://extend-display") {
                                NotificationCenter.default.post(
                                    name: .extendScreen,
                                    object: nil,
                                    userInfo: nil
                                )
                                return
                            }
                            if script.contains("raycast://") {
                                if let url = URL(string: script) {
                                    NSWorkspace.shared.open(url)
                                }
                                return
                            }
                            if script.contains("FILE_CONVERTER") {
                                let input = script.split(separator: ",")[1]
                                let output = script.split(separator: ",")[2]
                                convertSelectedFiles(from: String(input), to: String(output))
                                return
                            }
                            if let message = runInlineBashScript(script: script), message.lowercased().contains("error") {
                                DispatchQueue.main.async {
                                    self.localError = message
                                    self.showsLocalError = true
                                }
                            }
                        }
                    case .multiselection:
                        if let objects = tool.objects {
                            objects.forEach { item in
                                runShortuct(for: item)
                            }
                        }
                    case .automation:
                        if let script = tool.scriptCode {
                            execute(script) { error in
                                if error.description.lowercased().contains("error") {
                                    DispatchQueue.main.async {
                                        self.localError = error.description
                                        self.showsLocalError = true
                                    }
                                }
                            }
                        }
                    case .macro:
                        if let script = tool.scriptCode {
                            keyRecorder.recordedKeys = script.split(separator: ",").map { .init(key: $0.base) }
                            keyRecorder.playMacro()
                        }
                    case .none:
                        break
                    }
                }
            }
        }
    }
    
    func convertSelectedFiles(from inputFormat: String, to outputFormat: String) {
        let appleScript = """
        tell application "Finder"
            set selectedFiles to selection
            set filePaths to ""
            repeat with aFile in selectedFiles
                set filePaths to filePaths & (POSIX path of (aFile as text)) & linefeed
            end repeat
            return filePaths
        end tell
        """

        let scriptProcess = Process()
        scriptProcess.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        scriptProcess.arguments = ["-e", appleScript]

        let outputPipe = Pipe()
        scriptProcess.standardOutput = outputPipe
        scriptProcess.standardError = outputPipe

        do {
            try scriptProcess.run()
            scriptProcess.waitUntilExit()

            let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else {
                print("Failed to decode AppleScript output.")
                return
            }

            let selectedFiles = output
                .split(separator: "\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { $0.lowercased().hasSuffix(".\(inputFormat.lowercased())") }

            if selectedFiles.isEmpty {
                print("No files with .\(inputFormat) extension selected.")
                return
            }

            let outputDir = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Desktop/converted_\(outputFormat.lowercased())_output")

            try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

            for file in selectedFiles {
                let inputURL = URL(fileURLWithPath: file)
                let outputFileName = inputURL.deletingPathExtension().lastPathComponent + ".\(outputFormat)"
                let outputPath = outputDir.appendingPathComponent(outputFileName).path

                let sipsProcess = Process()
                sipsProcess.executableURL = URL(fileURLWithPath: "/usr/bin/sips")
                sipsProcess.arguments = ["-s", "format", outputFormat, file, "--out", outputPath]

                let sipsPipe = Pipe()
                sipsProcess.standardOutput = sipsPipe
                sipsProcess.standardError = sipsPipe

                try sipsProcess.run()
                sipsProcess.waitUntilExit()

                print("Converted: \(file) -> \(outputPath)")
            }

            print("Done. Files saved in: \(outputDir.path)")
        } catch {
            print("Error during conversion: \(error)")
        }
    }
    
    func activateApp(named appName: String) {
        let apps = NSRunningApplication.runningApplications(withBundleIdentifier: appName)
        apps.first?.activate(options: [.activateAllWindows])
    }
    
    @discardableResult
    func runInlineBashScript(script: String) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", script]

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        do {
            try process.run()
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: outputData, encoding: .utf8)
        } catch {
            return "Error executing script: \(error)"
        }
    }
    
    func openShortcut(name: String) {
        if let url = URL(string: "shortcuts://run-shortcut?name=\(name)") {
            NSWorkspace.shared.open(url)
        }
    }
    
    func openWebPage(for webpageItem: ShortcutObject) {
        guard let path = webpageItem.path, let url = NSURL(string: path) as? URL else {
            return
        }
        
        switch webpageItem.browser {
        case .chrome:
            if let chromeURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.google.Chrome") {
                NSWorkspace.shared.open([url], withApplicationAt: chromeURL, configuration: NSWorkspace.OpenConfiguration()) { _, error in
                    if let error {
                        print("Failed to open URL in Chrome: \(error)")
                    }
                }
            } else {
                print("Google Chrome is not installed or not found.")
            }
        case .safari:
            NSWorkspace.shared.open(url, configuration: NSWorkspace.OpenConfiguration()) { _, error in
                if let error { print(error) }
            }
        case .orion:
            let config = NSWorkspace.OpenConfiguration()
                if let orionAppURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.kagi.kagimacOS") {
                    NSWorkspace.shared.open(
                        [url],
                        withApplicationAt: orionAppURL,
                        configuration: config
                    ) { (app, error) in
                        if let error = error {
                            print("Failed to open URL in Orion: \(error.localizedDescription)")
                        }
                    }
                } else {
                    print("Orion app not found")
                }
        case .none:
            break
        }
    }
    
    func openApp(at path: String) {
        let url = URL(fileURLWithPath: path)
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
    }
}
