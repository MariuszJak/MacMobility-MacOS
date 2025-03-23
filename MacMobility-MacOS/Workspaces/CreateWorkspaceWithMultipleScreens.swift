//
//  CreateWorkspaceWithMultipleScreens.swift
//  MacMobility-MacOS
//
//  Created by CoderBlocks on 06/03/2025.
//

import Foundation
import SwiftUI

struct CreateWorkspaceWithMultipleScreens: View {
    @ObservedObject var viewModel: CreateWorkspaceWithMultipleScreensViewModel
    
    weak var delegate: WorkspaceWindowDelegate?
    var size: Double = 100
    
    public init(viewModel: CreateWorkspaceWithMultipleScreensViewModel, delegate: WorkspaceWindowDelegate?) {
        self.viewModel = viewModel
        self.delegate = delegate
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("New Workspace")
                    .font(.system(size: 17.0, weight: .bold))
                    .padding([.horizontal, .top], 16)
                TextField(text: $viewModel.title) {
                    Text("Name")
                        .padding()
                }
                Spacer()
                Button("Save") {
                    if let workspace = viewModel.save() {
                        delegate?.saveWorkspace(with: workspace)
                        delegate?.close()
                    }
                }
                Image(systemName: "plus.circle.fill")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .padding([.horizontal, .top], 16.0)
            }
            Divider()
        }
        HStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 240))], spacing: 6) {
                    ForEach(viewModel.screens) { screen in
                        ConfigurableScreenView(id: screen.id, viewModel: .init(apps: screen.apps, addAction: screen.updateApps, removeAction: viewModel.removeScreen))
                    }
                    AddNewScreenView {
                        viewModel.addNewScreen()
                    }
                }
            }
            .frame(minWidth: 600, minHeight: 500)
            VStack(alignment: .leading) {
                TextField("Search...", text: $viewModel.searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.vertical, 16.0)
                ScrollView {
                    ForEach(viewModel.installedApps) { app in
                        HStack {
                            HStack {
                                Image(nsImage: NSWorkspace.shared.icon(forFile: app.path))
                                    .resizable()
                                    .frame(width: 32, height: 32)
                                    .cornerRadius(6)
                                Text(app.name)
                                    .font(.headline)
                                Spacer()
                            }
                            .onDrag {
                                NSItemProvider(object: app.path as NSString)
                            }
                        }
                        .padding(.vertical, 4)
                        
                    }
                    .onAppear(perform: viewModel.fetchInstalledApps)
                }
            }
        }
        .frame(minWidth: 800, minHeight: 500)
        .padding()
    }
    
    func createAppFromPath(_ path: String) -> AppInfo {
        let appName = URL(string: path)?.deletingPathExtension().lastPathComponent ?? ""
        return .init(id: UUID().uuidString, name: appName, path: path)
    }
    
    func openApp(at path: String) {
        let url = URL(fileURLWithPath: path)
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
    }
}

