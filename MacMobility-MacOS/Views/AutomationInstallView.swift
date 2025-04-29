//
//  AutomationInstallView.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 29/04/2025.
//

import SwiftUI

struct AutomationInstallView: View {
    var automationItem: AutomationItem
    var selectedScriptsAction: ([AutomationScript]) -> Void
    
    @State private var selectedScriptIDs: Set<UUID>
    
    init(automationItem: AutomationItem, selectedScriptsAction: @escaping ([AutomationScript]) -> Void) {
        self.automationItem = automationItem
        self.selectedScriptsAction = selectedScriptsAction
        _selectedScriptIDs = State(initialValue: Set(automationItem.scripts.map { $0.id }))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 12) {
                if let imageData = automationItem.imageData,
                   let nsImage = NSImage(data: imageData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Image(systemName: "bolt.fill")
                        .resizable()
                        .frame(width: 48, height: 48)
                        .foregroundColor(.accentColor)
                }
                
                Text(automationItem.title)
                    .font(.title)
                    .bold()
                Spacer()
            }
            .padding(.top)
            
            Divider()
            
            // Scripts section
            VStack(alignment: .leading, spacing: 12) {
                Text("Scripts")
                    .font(.headline)
                
                ScrollView {
                    ForEach(automationItem.scripts) { script in
                        HStack(alignment: .top) {
                            VStack(alignment: .leading) {
                                HStack {
                                    Toggle("", isOn: Binding(
                                        get: {
                                            selectedScriptIDs.contains(script.id)
                                        },
                                        set: { isSelected in
                                            if isSelected {
                                                selectedScriptIDs.insert(script.id)
                                            } else {
                                                selectedScriptIDs.remove(script.id)
                                            }
                                        }
                                    ))
                                    .toggleStyle(.switch)
                                    Text(script.name)
                                        .font(.system(size: 14))
                                        .padding(.bottom, 8.0)
                                }
                                Text(script.description)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.gray)
                                    .padding(.bottom, 8.0)
                            }
                            Spacer()
                        }
                    }
                }
            }
            
            Spacer()
            
            HStack {
                Spacer()
                Button("Install") {
                    let selectedScripts = automationItem.scripts.filter { selectedScriptIDs.contains($0.id) }
                    selectedScriptsAction(selectedScripts)
                }
                .keyboardShortcut(.defaultAction)
                Spacer()
            }
            .padding(.bottom)
        }
        .padding()
        .frame(minWidth: 400, minHeight: 400)
    }
}
