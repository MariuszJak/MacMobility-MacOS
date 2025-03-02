//
//  WorkspacesWindowView.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 27/02/2025.
//

import SwiftUI

struct AppInfo: Identifiable, Codable {
    let id: String
    let name: String
    let path: String
    
    public init(id: String, name: String, path: String) {
        self.id = id
        self.name = name
        self.path = path
    }
}

struct WorkspaceItem: Identifiable, Codable {
    var id: String
    let title: String
    let apps: [AppInfo]
}

// ---

struct AppSendableInfo: Identifiable, Codable {
    let id: String
    let name: String
    let path: String
    let imageData: Data?
    
    public init(id: String, name: String, path: String, imageData: Data?) {
        self.id = id
        self.name = name
        self.path = path
        self.imageData = imageData
    }
}

struct WorkspaceSendableItem: Identifiable, Codable {
    var id: String
    let title: String
    let apps: [AppSendableInfo]
    
    public init(id: String, title: String, apps: [AppSendableInfo]) {
        self.id = id
        self.title = title
        self.apps = apps
    }
}

// ---

protocol WorkspaceWindowDelegate: AnyObject {
    func saveWorkspace(with item: WorkspaceItem)
    var close: () -> Void { get }
}

struct WorkspacesWindowView: View {
    @State private var newWindow: NSWindow?
    @State private var allBrowserwWindow: NSWindow?
    @State private var installedApps: [AppInfo] = []
    @StateObject var viewModel: WorkspacesWindowViewModel
    let connectionManager: ConnectionManager
    let closeAction: () -> Void
    
    init(connectionManager: ConnectionManager, closeAction: @escaping () -> Void) {
        self.connectionManager = connectionManager
        self.closeAction = closeAction
        self._viewModel = .init(wrappedValue: .init(connectionManager: connectionManager))
    }
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Workspaces")
                            .font(.system(size: 17.0, weight: .bold))
                            .padding([.horizontal, .top], 16)
                        Spacer()
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .onTapGesture {
                                openCreateNewWorkspaceWindow()
                            }
                            .padding([.horizontal, .top], 16.0)
                    }
                    Divider()
                    if !viewModel.workspaces.isEmpty {
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 240))], spacing: 6) {
                                ForEach(viewModel.workspaces) { workspace in
                                    VStack(alignment: .leading) {
                                        VStack(alignment: .leading) {
                                            HStack(alignment: .top) {
                                                Text(workspace.title)
                                                    .lineLimit(1)
                                                    .font(.system(size: 16, weight: .bold))
                                                    .padding(.bottom, 8)
                                            }
                                            HStack(spacing: 4) {
                                                ForEach(workspace.apps) { app in
                                                    Image(nsImage: NSWorkspace.shared.icon(forFile: app.path))
                                                        .resizable()
                                                        .frame(width: 38, height: 38)
                                                        .cornerRadius(3)
                                                        .onTapGesture {
                                                            openApp(at: app.path)
                                                        }
                                                }
                                            }
                                            .padding(.bottom, 20.0)
                                            Divider()
                                            HStack {
                                                Image(systemName: "arrow.up.right.square")
                                                    .resizable()
                                                    .frame(width: 16, height: 16)
                                                    .onTapGesture {
                                                        workspace.apps.forEach { app in
                                                            openApp(at: app.path)
                                                        }
                                                        closeAction()
                                                    }
                                                Image(systemName: "gear")
                                                    .resizable()
                                                    .frame(width: 16, height: 16)
                                                    .onTapGesture {
                                                        openCreateNewWorkspaceWindow(workspace)
                                                    }
                                                Image(systemName: "trash")
                                                    .resizable()
                                                    .frame(width: 16, height: 16)
                                                    .onTapGesture {
                                                        viewModel.removeWorkspace(with: workspace)
                                                    }
                                                Spacer()
                                            }
                                        }
                                        .padding(.all, 10)
                                    }
                                    .padding(.all, 18)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(Color.gray.opacity(0.1))
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        .scrollIndicators(.hidden)
                        .padding(.top, 16.0)
                    } else {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                VStack {
                                    Text("No workspaces found.")
                                        .font(.system(size: 24, weight: .medium))
                                        .padding(.bottom, 12.0)
                                    Button {
                                        openCreateNewWorkspaceWindow()
                                    } label: {
                                        Text("Add new one!")
                                            .font(.system(size: 16.0))
                                    }
                                }
                                Spacer()
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
        .padding()
    }
    
    func openApp(at path: String) {
        let url = URL(fileURLWithPath: path)
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
    }
    
    private func openCreateNewWorkspaceWindow(_ item: WorkspaceItem? = nil) {
        if nil == newWindow {
            newWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 800, height: 500),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            newWindow?.center()
            newWindow?.setFrameAutosaveName("New Workspace")
            newWindow?.isReleasedWhenClosed = false
            newWindow?.titlebarAppearsTransparent = true
            newWindow?.styleMask.insert(.fullSizeContentView)
            
            guard let visualEffect = NSVisualEffectView.createVisualAppearance(for: newWindow) else {
                return
            }
            let test = CreateWorkspace(viewModel: .init(workspace: item), delegate: viewModel)
            newWindow?.contentView?.addSubview(visualEffect, positioned: .below, relativeTo: nil)
            let hv = NSHostingController(rootView: test)
            newWindow?.contentView?.addSubview(hv.view)
            hv.view.frame = newWindow?.contentView?.bounds ?? .zero
            hv.view.autoresizingMask = [.width, .height]
            
            viewModel.close = {
                newWindow?.close()
            }
            
            NotificationCenter.default.addObserver(
                   forName: NSWindow.willCloseNotification,
                   object: newWindow,
                   queue: .main
               ) { _ in
                   test.viewModel.items.removeAll()
               }
        }
        newWindow?.contentView = NSHostingView(rootView: CreateWorkspace(viewModel: .init(workspace: item), delegate: viewModel))
        newWindow?.makeKeyAndOrderFront(nil)
    }
}

class CreateWorkspaceViewModel: ObservableObject {
    @Published var items: [AppInfo]
    @Published var title: String
    @Published var searchText: String = ""
    @Published var cancellables = Set<AnyCancellable>()
    @Published var installedApps: [AppInfo] = []
    var id: String
    
    public init(workspace: WorkspaceItem? = nil) {
        self.items = workspace?.apps ?? []
        self.title = workspace?.title ?? ""
        self.id = workspace?.id ?? UUID().uuidString
        registerListener()
    }
    
    func registerListener() {
        $searchText
            .sink { [weak self] _ in
                self?.fetchInstalledApps()
            }
            .store(in: &cancellables)
    }
    
    func removeItem(with path: String) {
        items = items.filter { $0.path != path }
    }
    
    func save() -> WorkspaceItem? {
        guard !title.isEmpty && !items.isEmpty else {
            return nil
        }
        return .init(id: id, title: title, apps: items)
    }
    
    func fetchInstalledApps() {
        let appDirectories = [
            "/Applications",
            "/System/Applications/Utilities"
        ]

        var apps: [AppInfo] = []

        for directory in appDirectories {
            apps.append(contentsOf: findApps(in: directory))
        }

        DispatchQueue.main.async {
            if self.searchText.isEmpty {
                self.installedApps = apps.sorted { $0.name.lowercased() < $1.name.lowercased() }
            } else {
                self.installedApps = apps.sorted { $0.name.lowercased() < $1.name.lowercased() }.filter { $0.name.contains(self.searchText) }
            }
        }
    }
    
    func findApps(in directory: String) -> [AppInfo] {
        var apps: [AppInfo] = []

        if let appURLs = try? FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: directory), includingPropertiesForKeys: nil, options: .skipsHiddenFiles) {
            for appURL in appURLs where appURL.pathExtension == "app" {
                let appName = appURL.deletingPathExtension().lastPathComponent
                apps.append(AppInfo(id: UUID().uuidString, name: appName, path: appURL.path))
            }
        }

        return apps
    }
}

import Combine

struct CreateWorkspace: View {
    @ObservedObject var viewModel: CreateWorkspaceViewModel
    
    
    weak var delegate: WorkspaceWindowDelegate?
    var size: Double = 100
    
    public init(viewModel: CreateWorkspaceViewModel, delegate: WorkspaceWindowDelegate?) {
        self.viewModel = viewModel
        self.delegate = delegate
    }
    
    var body: some View {
        HStack {
            VStack {
                Text("Create new workspace")
                    .font(.system(size: 24.0, weight: .bold))
                    .padding()
                VStack(alignment: .leading) {
                    Text("Name your workspace")
                    TextField(text: $viewModel.title) {
                        Text("Name")
                            .padding()
                    }
                }
                .padding(.bottom, 16.0)
                Spacer()
                if viewModel.items.isEmpty {
                    Text("Drag & Drop apps")
                        .background(
                            RoundedRectangle(cornerRadius: 20.0)
                                .fill(Color.black.opacity(0.6))
                                .frame(width: 200, height: 200)
                        )
                        .frame(width: 200, height: 200)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: size))], spacing: 8) {
                            ForEach(viewModel.items) { app in
                                ZStack {
                                    VStack {
                                        Image(nsImage: NSWorkspace.shared.icon(forFile: app.path))
                                            .resizable()
                                            .frame(width: 64, height: 64)
                                            .cornerRadius(6)
                                        Text(app.name)
                                            .multilineTextAlignment(.center)
                                            .font(.headline)
                                    }
                                    .frame(width: 150, height: 100)
                                    HStack {
                                        Spacer().frame(width: 50.0)
                                        RedXButton {
                                            viewModel.removeItem(with: app.path)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .scrollIndicators(.hidden)
                    .frame(minWidth: 350, maxHeight: 350)
                    .background(Color.black.cornerRadius(20.0).opacity(0.8))
                    Spacer()
                    VStack(alignment: .center) {
                        Button {
                            if let workspace = viewModel.save() {
                                delegate?.saveWorkspace(with: workspace)
                                delegate?.close()
                            }
                        } label: {
                            Text("Save")
                                .font(.system(size: 12.0))
                        }
                    }
                    Spacer()
                }
            }
            .onDrop(of: [.text], isTargeted: nil) { providers in
                providers.first?.loadObject(ofClass: NSString.self) { (droppedItem, _) in
                    if let droppedString = droppedItem as? String {
                        DispatchQueue.main.async {
                            if viewModel.items.count < 6 {
                                if !viewModel.items.contains(where: { $0.path == createAppFromPath(droppedString).path }) {
                                    viewModel.items.append(createAppFromPath(droppedString))
                                }
                                
                            } else {
                                print("ERROR")
                            }
                        }
                    }
                }
                return true
            }
            VStack {
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
                            }
                            .onDrag {
                                NSItemProvider(object: app.path as NSString)
                            }
                            
                            Spacer()
                            
                            Button("Launch") {
                                openApp(at: app.path)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            .padding(.trailing, 22.0)
                        }
                        .padding(.vertical, 4)
                        
                    }
                    .onAppear(perform: viewModel.fetchInstalledApps)
                }
            }
        }
        .frame(minWidth: 400, minHeight: 200)
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


struct RedXButton: View {
    var action: () -> Void
    
    var body: some View {
        Image(systemName: "xmark")
            .frame(width: 25, height: 25)
            .background(Color.red)
            .clipShape(Circle())
            .shadow(radius: 5.0)
            .onTapGesture {
                action()
            }
    }
}
