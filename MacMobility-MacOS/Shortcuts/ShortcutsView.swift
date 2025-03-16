//
//  ShortcutsView.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 16/03/2025.
//

import SwiftUI

struct ShortcutsView: View {
    @State private var shortcuts: [String] = []
    
    var body: some View {
        VStack {
            List(shortcuts, id: \.self) { shortcut in
                Button(action: {
                    openShortcut(name: shortcut)
                }) {
                    Text(shortcut)
                }
            }
        }
        .padding()
        .onAppear {
            shortcuts = getShortcutsList()
        }
    }
    
    func runShortcut(name: String) {
        let process = Process()
        process.launchPath = "/usr/bin/shortcuts"
        process.arguments = ["run", name]
        
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            print("Failed to run shortcut: \(error)")
        }
    }
    
    func openShortcut(name: String) {
        if let url = URL(string: "shortcuts://run-shortcut?name=\(name)") {
            NSWorkspace.shared.open(url)
        }
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
            
            return output?.components(separatedBy: "\n").filter { !$0.isEmpty } ?? []
        } catch {
            print("Failed to fetch shortcuts: \(error)")
            return []
        }
    }
}
