//
//  AutomationInstallView.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 29/04/2025.
//

import SwiftUI

class AutomationInstallViewModel: ObservableObject {
    @Published var localUnnamedScript: AutomationScript?
    @Published var showDependenciesView: Bool = false
}

struct AutomationInstallView: View {
    @ObservedObject var viewModel = AutomationInstallViewModel()
    var automationItem: AutomationItem
    var selectedScriptsAction: ([AutomationScript]) -> Void
    var close: () -> Void
    
    @State private var selectedScriptIDs: Set<UUID>
    
    init(automationItem: AutomationItem, selectedScriptsAction: @escaping ([AutomationScript]) -> Void, close: @escaping () -> Void) {
        self.automationItem = automationItem
        self.selectedScriptsAction = selectedScriptsAction
        self.close = close
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
            
            Text(automationItem.description)
                .font(.subheadline)
                .foregroundStyle(Color.gray)
                .padding(.bottom, 12.0)
            
            Divider()
            
            // Scripts section
            VStack(alignment: .leading, spacing: 12) {
                Text("Scripts")
                    .font(.headline)
                
                ScrollView {
                    ForEach(automationItem.scripts) { script in
                        HStack(alignment: .top) {
                            VStack(alignment: .leading) {
                                HStack(alignment: .top) {
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
//                                    .toggleStyle(.switch)
                                    Text(script.name)
                                        .font(.system(size: 14))
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
                    // There can be only one script with undefined name!
                    if selectedScripts.count == 1,
                        let unnamedScript = selectedScripts.first(where: { $0.name == "[UNDEFINED]" }) {
                        viewModel.localUnnamedScript = unnamedScript
                        viewModel.showDependenciesView = true
                    } else {
                        selectedScriptsAction(selectedScripts)
                    }
                }
                .keyboardShortcut(.defaultAction)
                Button("Close") {
                    close()
                }
                Spacer()
            }
            .padding(.bottom)
            .sheet(isPresented: $viewModel.showDependenciesView) {
                if let localUnnamedScript = viewModel.localUnnamedScript {
                    UnnamedScriptInstallView(script: localUnnamedScript) { updatedScript in
                        viewModel.showDependenciesView = false
                        selectedScriptsAction([updatedScript])
                    }
                }
            }
        }
        .padding()
        .frame(minWidth: 400, minHeight: 400)
    }
}
