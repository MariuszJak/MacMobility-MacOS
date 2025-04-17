//
//  ShortcutsView.swift
//  MacMobility-MacOS
//
//  Created by CoderBlocks on 16/03/2025.
//

import SwiftUI

struct ShortcutsView: View {
    @State private var newWindow: NSWindow?
    @State private var shortcutsToInstallWindow: NSWindow?
    @State private var automationsToInstallWindow: NSWindow?
    @State private var automationItemWindow: NSWindow?
    @State private var editUtilitiesWindow: NSWindow?
    @ObservedObject private var viewModel: ShortcutsViewModel
    @State private var selectedTab = 0
    let cornerRadius = 17.0
    
    init(viewModel: ShortcutsViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Editor")
                    .font(.system(size: 17.0, weight: .bold))
                    .foregroundStyle(Color.white)
                    
                Button("Add Page") {
                    viewModel.addPage()
                }
                .padding(.all, 3.0)
                
                Button("Explore Automations") {
                    openInstallAutomationsWindow()
                }
                .padding(.all, 3.0)
            }
            .padding([.horizontal, .top], 16)
            .padding(.leading, 21.0)
            Divider()
        }
        .padding(.top, 21.0)
        HStack {
            VStack(alignment: .leading) {
                ScrollViewReader { proxy in
                    ScrollView {
                        ForEach(1..<viewModel.pages+1, id: \.self) { page in
                            HStack {
                                Text("Page: \(page)")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(Color.white)
                                Spacer()
                                Button {
                                    viewModel.removePage(with: page)
                                } label: {
                                    Text("Remove")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Color.red)
                                }
                            }
                            .padding()
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 10) {
                                ForEach(0..<21) { index in
                                    VStack {
                                        ZStack {
                                            itemViews(for: index, page: page)
                                                .frame(width: 70, height: 70)
                                                .clipped()
                                            if let id = viewModel.objectAt(index: index, page: page)?.id {
                                                VStack {
                                                    HStack {
                                                        Spacer()
                                                        RedXButton {
                                                            viewModel.removeShortcut(id: id)
                                                        }
                                                    }
                                                    Spacer()
                                                }
                                            }
                                            
                                        }
                                    }
                                    .frame(width: 70, height: 70)
                                    .background(
                                        RoundedRectangle(cornerRadius: cornerRadius)
                                            .fill(Color.black.opacity(0.4))
                                    )
                                    .ifLet(viewModel.objectAt(index: index, page: page)?.id) { view, id in
                                        view.onDrag {
                                            NSItemProvider(object: id as NSString)
                                        }
                                    }
                                    .onDrop(of: [.text], isTargeted: nil) { providers in
                                        providers.first?.loadObject(ofClass: NSString.self) { (droppedItem, _) in
                                            if let droppedString = droppedItem as? String, let object = viewModel.object(for: droppedString) {
                                                handleOnDrop(index: index, page: page, object: object)
                                            }
                                        }
                                        return true
                                    }
                                }
                            }
                            .padding([.horizontal, .top])
                            .id(page)
                        }
                        Spacer()
                            .frame(height: 80)
                    }
                    .frame(minWidth: 600)
                    .scrollIndicators(.hidden)
                    .padding(.horizontal, 100)
                    .onChange(of: viewModel.scrollToPage) { _, page in
                        withAnimation {
                            proxy.scrollTo(page, anchor: .top)
                        }
                    }
                }
            }
            VStack {
                TextField("Search...", text: $viewModel.searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding([.horizontal, .bottom], 16.0)
                TabView(selection: $selectedTab) {
                    installedAppsView
                        .tabItem( { Text("Applications") })
                        .tag(0)
                    shortcutsView
                        .tabItem( { Text("Shortcuts") })
                        .tag(1)
                    websitesView
                        .tabItem( { Text("Websites") })
                        .tag(2)
                    utilitiesView
                        .tabItem( { Text("Utilities") })
                        .tag(3)
                }
                .tabViewStyle(.automatic)
                .padding([.horizontal, .bottom])
                .onChange(of: selectedTab) { _, _ in
                    viewModel.searchText = ""
                }
            }
        }
        .onAppear {
            for window in NSApplication.shared.windows {
                window.appearance = NSAppearance(named: .darkAqua)
            }
        }
        .padding(.top, 21.0)
    }
    
    private func handleOnDrop(index: Int, page: Int, object: ShortcutObject) {
        DispatchQueue.main.async {
            viewModel.addConfiguredShortcut(object:
                    .init(
                        type: object.type,
                        page: page,
                        index: index,
                        path: object.path,
                        id: object.id,
                        title: object.title,
                        color: object.color,
                        faviconLink: object.faviconLink,
                        browser: object.browser,
                        imageData: object.imageData,
                        scriptCode: object.scriptCode,
                        utilityType: object.utilityType,
                        objects: object.objects,
                        showTitleOnIcon: object.showTitleOnIcon ?? true
                    )
            )
        }
    }
    
    @ViewBuilder
    private func itemViews(for index: Int, page: Int) -> some View {
        if let object = viewModel.objectAt(index: index, page: page) {
            if let path = object.path, object.type == .app {
                Image(nsImage: NSWorkspace.shared.icon(forFile: path))
                    .resizable()
                    .scaledToFill()
                    .frame(width: 85, height: 85)
            } else if object.type == .shortcut {
                if let data = object.imageData, let image = NSImage(data: data) {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                        .cornerRadius(cornerRadius)
                        .frame(width: 70, height: 70)
                        .onTapGesture {
                            openEditUtilityWindow(item: object)
                        }
                }
                if object.showTitleOnIcon ?? true {
                    Text(object.title)
                        .font(.system(size: 12))
                        .multilineTextAlignment(.center)
                        .padding(.all, 3)
                        .stroke(color: Color.black)
                }
            } else if object.type == .webpage {
                if let data = object.imageData, let image = NSImage(data: data) {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .cornerRadius(cornerRadius)
                        .frame(width: 70, height: 70)
                        .clipShape(
                            RoundedRectangle(cornerRadius: cornerRadius)
                        )
                        .onTapGesture {
                            openCreateNewWebpageWindow(item: object)
                        }
                    if object.showTitleOnIcon ?? true {
                        Text(object.title)
                            .font(.system(size: 12))
                            .multilineTextAlignment(.center)
                            .padding(.all, 3)
                            .stroke(color: Color.black)
                            .onTapGesture {
                                openCreateNewWebpageWindow(item: object)
                            }
                    }
                } else if let path = object.browser?.icon {
                    Image(path)
                        .resizable()
                        .frame(width: 80, height: 80)
                        .cornerRadius(cornerRadius)
                        .onTapGesture {
                            openCreateNewWebpageWindow(item: object)
                        }
                    if object.showTitleOnIcon ?? true {
                        Text(object.title)
                            .font(.system(size: 12))
                            .multilineTextAlignment(.center)
                            .padding(.all, 3)
                            .stroke(color: Color.black)
                            .onTapGesture {
                                openCreateNewWebpageWindow(item: object)
                            }
                    }
                }
            } else if object.type == .utility {
                if let data = object.imageData, let image = NSImage(data: data) {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                        .cornerRadius(cornerRadius)
                        .frame(width: 70, height: 70)
                        .onTapGesture {
                            openEditUtilityWindow(item: object)
                        }
                }
                if !object.title.isEmpty {
                    if object.showTitleOnIcon ?? true {
                        Text(object.title)
                            .font(.system(size: 11))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .frame(maxWidth: 80)
                            .stroke(color: Color.black)
                            .onTapGesture {
                                openEditUtilityWindow(item: object)
                            }
                    }
                }
            }
        }
    }
    
    private var shortcutsView: some View {
        VStack(alignment: .leading) {
            if viewModel.shortcuts.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack {
                            Text("No shortcuts found.")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundStyle(Color.white)
                                .padding(.bottom, 12.0)
                            Button {
                                openInstallShortcutsWindow()
                            } label: {
                                Text("Add new one!")
                                    .font(.system(size: 16.0))
                                    .foregroundStyle(Color.white)
                            }
                        }
                        Spacer()
                    }
                    Spacer()
                }
                .padding(.bottom, 8.0)
            } else {
                ScrollView {
                    ForEach(viewModel.shortcuts) { shortcut in
                        HStack {
                            if let data = shortcut.imageData, let image = NSImage(data: data) {
                                Image(nsImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .cornerRadius(cornerRadius)
                                    .frame(width: 38, height: 38)
                            }
                            Text(shortcut.title)
                                .padding(.vertical, 6.0)
                            Spacer()
                        }
                        .onDrag {
                            NSItemProvider(object: shortcut.id as NSString)
                        }
                        Divider()
                    }
                }
                .padding(.bottom, 8.0)
            }
            Divider()
            Text("Explore our curated selection of premade shortcuts and boost your productivity effortlessly.")
                .font(.system(size: 14.0))
                .foregroundStyle(Color.gray)
                .padding(.bottom, 6.0)
            Button("Open Shortcuts") {
                openInstallShortcutsWindow()
            }
            .padding(.bottom, 8.0)
        }
        .padding()
    }
    
    @State private var appNameToFlash: String = ""
    
    private var installedAppsView: some View {
        VStack(alignment: .leading) {
            ScrollViewReader { proxy in
                ScrollView {
                    ForEach(viewModel.installedApps) { app in
                        HStack {
                            HStack {
                                Image(nsImage: NSWorkspace.shared.icon(forFile: app.path ?? ""))
                                    .resizable()
                                    .frame(width: 38, height: 38)
                                    .cornerRadius(cornerRadius)
                                    .padding(.trailing, 8)
                                Text(app.title)
                                    .padding(.vertical, 6.0)
                            }
                            .id(app.title)
                            Spacer()
                        }
                        .onDrag {
                            NSItemProvider(object: app.id as NSString)
                        }
                        .background(app.title == appNameToFlash ? Color.yellow.opacity(0.5) : Color.clear)
                        .animation(.easeOut, value: appNameToFlash)
                        .cornerRadius(10)
                        Divider()
                    }
                }
                .onChange(of: viewModel.scrollToApp) { _, title in
                    DispatchQueue.main.asyncAfter(deadline: .now()+0.3) {
                        withAnimation {
                            proxy.scrollTo(title, anchor: .center)
                        } completion: {
                            appNameToFlash = title
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                appNameToFlash = ""
                            }
                        }

                    }
                }
            }
            Divider()
            Text("Can't find app in the list above? Add it from Finder by clicking the button below.")
                .font(.system(size: 14.0))
                .foregroundStyle(Color.gray)
                .padding(.bottom, 6.0)
            Button("Click to add an app") {
                if let path = selectApp() {
                    viewModel.addInstalledApp(for: path)
                }
            }
            .padding(.bottom, 8.0)
        }
        .padding()
    }
    
    func selectApp() -> String? {
        let openPanel = NSOpenPanel()
        openPanel.title = "Select an Application"
        openPanel.allowedContentTypes = [.application]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        
        if openPanel.runModal() == .OK {
            return openPanel.url?.path
        }
        
        return nil
    }
    
    private var websitesView: some View {
        WebpagesWindowView(viewModel: viewModel)
    }
    
    private var utilitiesView: some View {
        UtilitiesWindowView(viewModel: viewModel)
    }
    
    private func openCreateNewWebpageWindow(item: ShortcutObject? = nil) {
        if nil == newWindow {
            newWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            newWindow?.center()
            newWindow?.setFrameAutosaveName("Webpages")
            newWindow?.isReleasedWhenClosed = false
            newWindow?.titlebarAppearsTransparent = true
            newWindow?.styleMask.insert(.fullSizeContentView)
            
            guard let visualEffect = NSVisualEffectView.createVisualAppearance(for: newWindow) else {
                return
            }
            newWindow?.contentView?.addSubview(visualEffect, positioned: .below, relativeTo: nil)
            let hv = NSHostingController(rootView: NewWebpageView(item: item, delegate: viewModel))
            viewModel.close = {
                newWindow?.close()
            }
            newWindow?.contentView?.addSubview(hv.view)
            hv.view.frame = newWindow?.contentView?.bounds ?? .zero
            hv.view.autoresizingMask = [.width, .height]
            newWindow?.makeKeyAndOrderFront(nil)
            return
        }
        newWindow?.contentView?.subviews.forEach { $0.removeFromSuperview() }
        let hv = NSHostingController(rootView: NewWebpageView(item: item, delegate: viewModel))
        viewModel.close = {
            newWindow?.close()
        }
        newWindow?.contentView?.addSubview(hv.view)
        hv.view.frame = newWindow?.contentView?.bounds ?? .zero
        hv.view.autoresizingMask = [.width, .height]
        newWindow?.makeKeyAndOrderFront(nil)
    }
    
    private func openInstallShortcutsWindow() {
        if nil == shortcutsToInstallWindow {
            shortcutsToInstallWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 500, height: 700),
                styleMask: [.titled, .closable, .resizable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            shortcutsToInstallWindow?.center()
            shortcutsToInstallWindow?.setFrameAutosaveName("ShortcutsToInstallWindow")
            shortcutsToInstallWindow?.isReleasedWhenClosed = false
            shortcutsToInstallWindow?.titlebarAppearsTransparent = true
            shortcutsToInstallWindow?.styleMask.insert(.fullSizeContentView)
            
            guard let visualEffect = NSVisualEffectView.createVisualAppearance(for: shortcutsToInstallWindow) else {
                return
            }
            shortcutsToInstallWindow?.contentView?.addSubview(visualEffect, positioned: .below, relativeTo: nil)
            let hv = NSHostingController(rootView: ShortcutInstallView())
            shortcutsToInstallWindow?.contentView?.addSubview(hv.view)
            hv.view.frame = shortcutsToInstallWindow?.contentView?.bounds ?? .zero
            hv.view.autoresizingMask = [.width, .height]
            shortcutsToInstallWindow?.makeKeyAndOrderFront(nil)
            return
        }
        shortcutsToInstallWindow?.makeKeyAndOrderFront(nil)
    }
    
    private func openInstallAutomationsWindow() {
        if nil == automationsToInstallWindow {
            automationsToInstallWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 500, height: 700),
                styleMask: [.titled, .closable, .resizable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            automationsToInstallWindow?.center()
            automationsToInstallWindow?.setFrameAutosaveName("AutomationsToInstallWindow")
            automationsToInstallWindow?.isReleasedWhenClosed = false
            automationsToInstallWindow?.titlebarAppearsTransparent = true
            automationsToInstallWindow?.styleMask.insert(.fullSizeContentView)
            
            guard let visualEffect = NSVisualEffectView.createVisualAppearance(for: automationsToInstallWindow) else {
                return
            }
            automationsToInstallWindow?.contentView?.addSubview(visualEffect, positioned: .below, relativeTo: nil)
            let hv = NSHostingController(rootView: ExploreAutomationsView(openDetailsPage: { item in
                openAutomationItemWindow(item)
            }))
            automationsToInstallWindow?.contentView?.addSubview(hv.view)
            hv.view.frame = automationsToInstallWindow?.contentView?.bounds ?? .zero
            hv.view.autoresizingMask = [.width, .height]
            automationsToInstallWindow?.makeKeyAndOrderFront(nil)
            return
        }
        automationsToInstallWindow?.makeKeyAndOrderFront(nil)
    }
    
    private func openAutomationItemWindow(_ item: AutomationItem) {
        if nil == automationItemWindow {
            automationItemWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 500, height: 700),
                styleMask: [.titled, .closable, .resizable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            automationItemWindow?.center()
            automationItemWindow?.setFrameAutosaveName("AutomationsToInstallWindow")
            automationItemWindow?.isReleasedWhenClosed = false
            automationItemWindow?.titlebarAppearsTransparent = true
            automationItemWindow?.styleMask.insert(.fullSizeContentView)
            
            guard let visualEffect = NSVisualEffectView.createVisualAppearance(for: automationItemWindow) else {
                return
            }
            automationItemWindow?.contentView?.addSubview(visualEffect, positioned: .below, relativeTo: nil)
            let hv = NSHostingController(rootView: AutomationInstallView(automationItem: item, selectedScriptsAction: { scripts in
                viewModel.addAutomations(from: scripts)
            }))
            automationItemWindow?.contentView?.addSubview(hv.view)
            hv.view.frame = automationItemWindow?.contentView?.bounds ?? .zero
            hv.view.autoresizingMask = [.width, .height]
            automationItemWindow?.makeKeyAndOrderFront(nil)
            return
        }
        automationItemWindow?.contentView?.subviews.forEach { $0.removeFromSuperview() }
        let hv = NSHostingController(rootView: AutomationInstallView(automationItem: item, selectedScriptsAction: { scripts in
            viewModel.addAutomations(from: scripts)
        }))
        automationItemWindow?.contentView?.addSubview(hv.view)
        hv.view.frame = automationItemWindow?.contentView?.bounds ?? .zero
        hv.view.autoresizingMask = [.width, .height]
        automationItemWindow?.makeKeyAndOrderFront(nil)
    }
    
    private func openEditUtilityWindow(item: ShortcutObject) {
        if nil == editUtilitiesWindow {
            editUtilitiesWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 320, height: 570),
                styleMask: item.utilityType == .commandline || item.utilityType == .automation ? [.titled, .closable, .resizable, .miniaturizable] : [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            editUtilitiesWindow?.center()
            editUtilitiesWindow?.setFrameAutosaveName("Utilities")
            editUtilitiesWindow?.isReleasedWhenClosed = false
            editUtilitiesWindow?.titlebarAppearsTransparent = true
            editUtilitiesWindow?.styleMask.insert(.fullSizeContentView)
            
            guard let visualEffect = NSVisualEffectView.createVisualAppearance(for: editUtilitiesWindow) else {
                return
            }
            
            editUtilitiesWindow?.contentView?.addSubview(visualEffect, positioned: .below, relativeTo: nil)
            switch item.utilityType {
            case .commandline:
                let hv = NSHostingController(rootView: NewBashUtilityView(item: item, delegate: viewModel) {
                    editUtilitiesWindow?.close()
                })
                editUtilitiesWindow?.contentView?.addSubview(hv.view)
                hv.view.frame = editUtilitiesWindow?.contentView?.bounds ?? .zero
                hv.view.autoresizingMask = [.width, .height]
            case .multiselection:
                let hv = NSHostingController(rootView: NewMultiSelectionUtilityView(item: item, delegate: viewModel) {
                    editUtilitiesWindow?.close()
                })
                editUtilitiesWindow?.contentView?.addSubview(hv.view)
                hv.view.frame = editUtilitiesWindow?.contentView?.bounds ?? .zero
                hv.view.autoresizingMask = [.width, .height]
            case .automation:
                let hv = NSHostingController(rootView: NewAutomationUtilityView(item: item, delegate: viewModel) {
                    editUtilitiesWindow?.close()
                })
                editUtilitiesWindow?.contentView?.addSubview(hv.view)
                hv.view.frame = editUtilitiesWindow?.contentView?.bounds ?? .zero
                hv.view.autoresizingMask = [.width, .height]
            case .none:
                break
            }
            editUtilitiesWindow?.makeKeyAndOrderFront(nil)
            return
        }
        editUtilitiesWindow?.contentView?.subviews.forEach { $0.removeFromSuperview() }
        switch item.utilityType {
        case .commandline:
            let hv = NSHostingController(rootView: NewBashUtilityView(item: item, delegate: viewModel) {
                editUtilitiesWindow?.close()
            })
            editUtilitiesWindow?.contentView?.addSubview(hv.view)
            hv.view.frame = editUtilitiesWindow?.contentView?.bounds ?? .zero
            hv.view.autoresizingMask = [.width, .height]
        case .multiselection:
            let hv = NSHostingController(rootView: NewMultiSelectionUtilityView(item: item, delegate: viewModel) {
                editUtilitiesWindow?.close()
            })
            editUtilitiesWindow?.contentView?.addSubview(hv.view)
            hv.view.frame = editUtilitiesWindow?.contentView?.bounds ?? .zero
            hv.view.autoresizingMask = [.width, .height]
        case .automation:
            let hv = NSHostingController(rootView: NewAutomationUtilityView(item: item, delegate: viewModel) {
                editUtilitiesWindow?.close()
            })
            editUtilitiesWindow?.contentView?.addSubview(hv.view)
            hv.view.frame = editUtilitiesWindow?.contentView?.bounds ?? .zero
            hv.view.autoresizingMask = [.width, .height]
        case .none:
            break
        }
        editUtilitiesWindow?.makeKeyAndOrderFront(nil)
    }
}
