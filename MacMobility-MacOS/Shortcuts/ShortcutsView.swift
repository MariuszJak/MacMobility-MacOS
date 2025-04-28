//
//  ShortcutsView.swift
//  MacMobility-MacOS
//
//  Created by CoderBlocks on 16/03/2025.
//

import SwiftUI
import SwiftFX

struct ShortcutsView: View {
    @State private var newWindow: NSWindow?
    @State private var newUtilityWindow: NSWindow?
    @State private var shortcutsToInstallWindow: NSWindow?
    @State private var automationsToInstallWindow: NSWindow?
    @State private var automationItemWindow: NSWindow?
    @State private var editUtilitiesWindow: NSWindow?
    @State private var shouldShowCompanionRequestPopup: Bool = false
    @ObservedObject private var viewModel: ShortcutsViewModel
    @State private var selectedTab = 0
    @State private var tab: Tab = .apps
    @Namespace private var animation
    let cornerRadius = 17.0
    
    init(viewModel: ShortcutsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                pairiningView
                
                Divider()
                    .frame(height: 14.0)
                
                BlueButton(
                    title: "Automations",
                    font: .callout,
                    padding: 8.0,
                    cornerRadius: 6.0,
                    leadingImage: "sparkle",
                    backgroundColor: .accentColor
                ) {
                    openInstallAutomationsWindow()
                }
                .padding(.all, 3.0)
                
                Divider()
                    .frame(height: 14.0)
                
                BlueButton(
                    title: "New Page",
                    font: .callout,
                    padding: 8.0,
                    cornerRadius: 6.0,
                    backgroundColor: .clear
                ) {
                    viewModel.addPage()
                }
                .padding(.all, 3.0)
                
                Divider()
                    .frame(height: 14.0)
                
                BlueButton(
                    title: "Add App",
                    font: .callout,
                    padding: 8.0,
                    cornerRadius: 6.0,
                    backgroundColor: .clear
                ) {
                    tab = .apps
                    if let path = selectApp() {
                        viewModel.addInstalledApp(for: path)
                    }
                }
                .padding(.all, 3.0)
                
                BlueButton(
                    title: "Install Shortcuts",
                    font: .callout,
                    padding: 8.0,
                    cornerRadius: 6.0,
                    backgroundColor: .clear
                ) {
                    openInstallShortcutsWindow()
                }
                .padding(.all, 3.0)
                
                BlueButton(
                    title: "Add Link",
                    font: .callout,
                    padding: 8.0,
                    cornerRadius: 6.0,
                    backgroundColor: .clear
                ) {
                    openCreateNewWebpageWindow()
                }
                .padding(.all, 3.0)
                
                BlueButton(
                    title: "Add Utility",
                    font: .callout,
                    padding: 8.0,
                    cornerRadius: 6.0,
                    backgroundColor: .clear
                ) {
                    openCreateNewUtilityWindow()
                }
                .padding(.all, 3.0)
                
                Spacer()
                AnimatedSearchBar(searchText: $viewModel.searchText)
                    .padding(.trailing, 48.0)
            }
            .padding([.horizontal, .top], 16)
            .padding(.bottom, 8.0)
            .animation(.easeInOut, value: viewModel.connectionManager.pairingStatus)
            Divider()
        }
        .padding(.top, 21.0)
        .frame(minWidth: 1300.0)
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
                                        PlusButtonView()
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
                    .frame(minWidth: 600.0, maxWidth: 600.0)
                    .scrollIndicators(.hidden)
                    .padding(.horizontal, 28.0)
                    .onChange(of: viewModel.scrollToPage) { _, page in
                        withAnimation {
                            proxy.scrollTo(page, anchor: .top)
                        }
                    }
                }
            }
            VStack {
                CustomTabBar(selectedTab: $tab, animation: animation) {
                    viewModel.searchText = ""
                }
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
                .padding(.bottom, 16.0)
                .frame(minWidth: 500.0)
                
                Group {
                    switch tab {
                    case .apps:
                        installedAppsView
                    case .shortcuts:
                        shortcutsView
                    case .webpages:
                        websitesView
                    case .utilities:
                        utilitiesView
                    }
                }
                .frame(maxWidth: 500.0, maxHeight: .infinity)
            }
        }
        .onAppear {
            for window in NSApplication.shared.windows {
                window.appearance = NSAppearance(named: .darkAqua)
            }
        }
        .sheet(isPresented: $shouldShowCompanionRequestPopup) {
            CompanionRequestPopup(
                deviceName: viewModel.availablePeerName,
                onAccept: {
                    print("Accepted")
                    shouldShowCompanionRequestPopup = false
                },
                onDeny: {
                    print("Denied")
                    shouldShowCompanionRequestPopup = false
                }
            )
            .transition(.scale)
            .zIndex(1)
        }
        .frame(minWidth: 1300.0)
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
                        showTitleOnIcon: object.showTitleOnIcon ?? true,
                        category: object.category
                    )
            )
        }
    }
    
    @ViewBuilder
    private var pairiningView: some View {
        VStack {
            switch viewModel.connectionManager.pairingStatus {
            case .notPaired:
                if let availablePeer = viewModel.connectionManager.availablePeer {
                    BlueButton(
                        title: "Connect to \(availablePeer.displayName)",
                        font: .callout,
                        padding: 10.0,
                        cornerRadius: 6.0,
                        leadingImage: nil,
                        backgroundColor: .accentColor
                    ) {
                        viewModel.connectionManager.invitePeer(with: availablePeer)
                        viewModel.connectionManager.pairingStatus = .pairining
                    }
                    .padding(.all, 3.0)
                }
            case .paired:
                BlueButton(
                    title: "Disconnect from \(viewModel.connectionManager.connectedPeerName ?? "")",
                    font: .callout,
                    padding: 8.0,
                    cornerRadius: 6.0,
                    leadingImage: nil,
                    backgroundColor: .red
                ) {
                    viewModel.connectionManager.disconnect()
                    viewModel.connectionManager.pairingStatus = .notPaired
                }
                .padding(.all, 3.0)
            case .pairining:
                BlueButton(
                    title: "Cancel pairing",
                    font: .callout,
                    padding: 8.0,
                    cornerRadius: 6.0,
                    leadingImage: nil,
                    backgroundColor: .red
                ) {
                    viewModel.connectionManager.cancel()
                }
                .padding(.all, 3.0)
            }
        }
        .animation(.easeInOut, value: viewModel.connectionManager.pairingStatus)
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
                        .outlinedText()
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
                            .outlinedText()
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
                            .outlinedText()
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
                            .outlinedText()
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
                    Spacer()
                        .frame(height: 16.0)
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
                        .padding(.horizontal, 16.0)
                        .padding(.vertical, 6.0)
                        Divider()
                    }
                }
                .padding(.bottom, 8.0)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(NSColor.windowBackgroundColor))
                )
        )
        .padding(.bottom, 16.0)
    }
    
    @State private var appNameToFlash: String = ""
    
    private var installedAppsView: some View {
        VStack(alignment: .leading) {
            if viewModel.installedApps.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack {
                            Text("No app found.")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundStyle(Color.white)
                                .padding(.bottom, 12.0)
                            Button {
                                if let path = selectApp() {
                                    viewModel.addInstalledApp(for: path)
                                }
                            } label: {
                                Text("Search in Finder")
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
                ScrollViewReader { proxy in
                    ScrollView {
                        Spacer()
                            .frame(height: 16.0)
                        ForEach(viewModel.installedApps) { app in
                            HStack {
                                HStack {
                                    HStack {
                                        Image(nsImage: NSWorkspace.shared.icon(forFile: app.path ?? ""))
                                            .resizable()
                                            .frame(width: 46, height: 46)
                                            .cornerRadius(cornerRadius)
                                            .padding(.trailing, 8)
                                        Text(app.title)
                                            .padding(.vertical, 6.0)
                                    }
                                    .onDrag {
                                        NSItemProvider(object: app.id as NSString)
                                    }
                                    if let automation = viewModel.appHasAutomation(path: app.path ?? "") {
                                        Spacer()
                                        Button("Automation") {
                                            openAutomationItemWindow(automation)
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .tint(.blue)
                                    }
                                    if viewModel.isAppAddedByUser(path: app.path ?? "") {
                                        Spacer()
                                        Button("Remove") {
                                            viewModel.removeAppInstalledByUser(path: app.path ?? "")
                                        }
                                    }
                                }
                                .id(app.title)
                                Spacer()
                            }
                            
                            .background(app.title == appNameToFlash ? Color.yellow.opacity(0.5) : Color.clear)
                            .animation(.easeOut, value: appNameToFlash)
                            .cornerRadius(10)
                            .padding(.horizontal, 16.0)
                            .padding(.vertical, 6.0)
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
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(NSColor.windowBackgroundColor))
                )
        )
        .padding(.bottom, 16.0)
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
                contentRect: NSRect(x: 0, y: 0, width: 600, height: 550),
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
                tab = .webpages
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
            let hv = NSHostingController(rootView: ShortcutInstallView() {
                shortcutsToInstallWindow?.close()
                tab = .shortcuts
            })
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
                automationsToInstallWindow?.close()
            }))
            automationsToInstallWindow?.contentView?.addSubview(hv.view)
            hv.view.frame = automationsToInstallWindow?.contentView?.bounds ?? .zero
            hv.view.autoresizingMask = [.width, .height]
            automationsToInstallWindow?.makeKeyAndOrderFront(nil)
            return
        }
        automationsToInstallWindow?.makeKeyAndOrderFront(nil)
    }
    
    private func openCreateNewUtilityWindow() {
        if nil == newUtilityWindow {
            newUtilityWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 800, height: 400),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            newUtilityWindow?.center()
            newUtilityWindow?.setFrameAutosaveName("NewUtility")
            newUtilityWindow?.isReleasedWhenClosed = false
            newUtilityWindow?.contentView = NSHostingView(rootView: SelectUtilityTypeWindowView(
                connectionManager: viewModel.connectionManager,
                categories: viewModel.allCategories(),
                delegate: viewModel,
                closeAction: {
                    tab = .utilities
                    newUtilityWindow?.close()
                }))
        }
        newUtilityWindow?.contentView = NSHostingView(rootView: SelectUtilityTypeWindowView(
            connectionManager: viewModel.connectionManager,
            categories: viewModel.allCategories(),
            delegate: viewModel,
            closeAction: {
                tab = .utilities
                newUtilityWindow?.close()
            }))
        newUtilityWindow?.makeKeyAndOrderFront(nil)
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
                automationItemWindow?.close()
                tab = .utilities
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
                contentRect: NSRect(x: 0, y: 0, width: 520, height: 470),
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
                let hv = NSHostingController(rootView: NewBashUtilityView(categories: viewModel.allCategories(), item: item, delegate: viewModel) {
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
                let hv = NSHostingController(rootView: NewAutomationUtilityView(categories: viewModel.allCategories(), item: item, delegate: viewModel) {
                    editUtilitiesWindow?.close()
                })
                editUtilitiesWindow?.contentView?.addSubview(hv.view)
                hv.view.frame = editUtilitiesWindow?.contentView?.bounds ?? .zero
                hv.view.autoresizingMask = [.width, .height]
            case .macro:
                let hv = NSHostingController(rootView: MacroRecorderView(item: item, delegate: viewModel){
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
        editUtilitiesWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 470),
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
            let hv = NSHostingController(rootView: NewBashUtilityView(categories: viewModel.allCategories(), item: item, delegate: viewModel) {
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
            let hv = NSHostingController(rootView: NewAutomationUtilityView(categories: viewModel.allCategories(), item: item, delegate: viewModel) {
                editUtilitiesWindow?.close()
            })
            editUtilitiesWindow?.contentView?.addSubview(hv.view)
            hv.view.frame = editUtilitiesWindow?.contentView?.bounds ?? .zero
            hv.view.autoresizingMask = [.width, .height]
        case .macro:
            let hv = NSHostingController(rootView: MacroRecorderView(item: item, delegate: viewModel){
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

struct CompanionRequestPopup: View {
    let deviceName: String
    let onAccept: () -> Void
    let onDeny: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Companion Device Detected")
                .font(.title2)
                .fontWeight(.bold)

            Text("“\(deviceName)” wants to connect to this Mac.")
                .multilineTextAlignment(.center)
                .font(.body)
                .foregroundColor(.secondary)

            HStack(spacing: 16) {
                Button("Deny") {
                    onDeny()
                }
                .keyboardShortcut(.cancelAction)
                .buttonStyle(.bordered)

                Button("Accept") {
                    onAccept()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(minWidth: 320)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.thinMaterial)
                .shadow(radius: 10)
        )
        .padding()
    }
}
