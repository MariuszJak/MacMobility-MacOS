//
//  ShortcutsView.swift
//  MacMobility-MacOS
//
//  Created by CoderBlocks on 16/03/2025.
//

import SwiftUI
import Combine

enum StreamConnectionState {
    case notConnected
    case connecting
    case disconnecting
    case connected
    
    var label: String {
        switch self {
        case .notConnected:
            return "Extend Display"
        case .connecting:
            return "Connecting...."
        case .disconnecting:
            return "Disconnecting..."
        case .connected:
            return "Close Display"
        }
    }
}

struct ShortcutsView: View {
    @StateObject private var responder = HotKeyResponder.shared
    @ObservedObject private var viewModel: ShortcutsViewModel
    @State private var newWindow: NSWindow?
    @State private var newUtilityWindow: NSWindow?
    @State private var shortcutsToInstallWindow: NSWindow?
    @State private var automationsToInstallWindow: NSWindow?
    @State private var automationItemWindow: NSWindow?
    @State private var editUtilitiesWindow: NSWindow?
    @State private var companionAppWindow: NSWindow?
    @State private var quickActionSetupWindow: NSWindow?
    @State private var circularWindow: NSWindow?
    @State private var shouldShowCompanionRequestPopup: Bool = false
    @State private var selectedTab = 0
    @State private var tab: Tab = .apps
    
    @State private var resolutions: [DisplayMode] = []
    @State private var selectedMode: DisplayMode?
    @State private var cancellables = Set<AnyCancellable>()

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
                    title: "Store",
                    font: .callout,
                    padding: 8.0,
                    cornerRadius: 6.0,
                    leadingImage: "storefront.circle",
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
                
                switch viewModel.streamConnectionState {
                case .connected, .notConnected:
                    BlueButton(
                        title: viewModel.streamConnectionState.label,
                        font: .callout,
                        padding: 8.0,
                        cornerRadius: 6.0,
                        backgroundColor: .clear
                    ) {
                        switch viewModel.streamConnectionState {
                        case .notConnected:
                            viewModel.extendScreen()
                        case .connecting:
                            break
                        case .disconnecting:
                            break
                        case .connected:
                            viewModel.streamConnectionState = .disconnecting
                            viewModel.connectionManager.stopTCPServer { _ in
                                viewModel.streamConnectionState = .notConnected
                            }
                        }
                    }
                    .disabled(viewModel.connectionManager.pairingStatus != .paired)
                    .padding(.all, 3.0)
                case .connecting:
                    BlueButton(
                        title: "Connecting...",
                        font: .callout,
                        padding: 8.0,
                        cornerRadius: 6.0,
                        backgroundColor: .red
                    ) {
                        viewModel.connectionManager.stopTCPServer { _ in
                            viewModel.streamConnectionState = .notConnected
                        }
                    }
                    .padding(.all, 3.0)
                case .disconnecting:
                    BlueButton(
                        title: viewModel.streamConnectionState.label,
                        font: .callout,
                        padding: 8.0,
                        cornerRadius: 6.0,
                        backgroundColor: .red
                    ) {
                    }
                    .padding(.all, 3.0)
                }
                BlueButton(
                    title: "Quick Action Menu",
                    font: .callout,
                    padding: 8.0,
                    cornerRadius: 6.0,
                    backgroundColor: .clear
                ) {
                    openQuickActionWindow()
                }
                .padding(.all, 3.0)
                Spacer()
                AnimatedSearchBar(searchText: $viewModel.searchText)
                    .padding(.all, 3.0)
                BlueButton(
                    title: "Get Companion App",
                    font: .callout,
                    padding: 8.0,
                    cornerRadius: 6.0,
                    backgroundColor: .clear
                ) {
                    openCompanionAppWindow()
                }
                .padding(.all, 3.0)
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
                        if viewModel.streamConnectionState == .connected, let displayID = viewModel.displayID, let iosDevice = viewModel.connectionManager.iosDevice {
                            ResolutionSelectorCard(displayID: displayID, iosDevice: iosDevice, bitrate: $viewModel.connectionManager.bitrate)
                        }
                        ForEach(1..<viewModel.pages+1, id: \.self) { page in
                            HStack(alignment: .bottom) {
                                pageNumberView(page: page)
                                Spacer()
                                #if DEBUG
                                Button {
                                    viewModel.exportPageAsAutomations(number: page)
                                } label: {
                                    Text("Export")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Color.red)
                                }
                                #endif
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
                                                            viewModel.removeShortcut(id: id, page: page)
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
                    .onChange(of: viewModel.connectionManager.pairingStatus) { _, newValue in
                        if newValue == .notPaired {
                            viewModel.connectionManager.stopTCPServer { success in
                                print("Disconnected from server: \(success)")
                            }
                            viewModel.streamConnectionState = .notConnected
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
            setupKeyboardListener()
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
        .sheet(isPresented: $viewModel.showDependenciesView) {
            DependenciesInstallView(dependencies: viewModel.dependenciesObjects, dependencyUpdate: viewModel.dependencyUpdate)
        }
        .frame(minWidth: 1300.0)
        .padding(.top, 21.0)
    }
    
    func setupKeyboardListener() {
        guard !viewModel.connectionManager.listenerAdded else { return }
        HotKeyManager.shared.registerHotKey()
        
        responder
            .$showWindow
            .receive(on: DispatchQueue.main)
            .sink { value in
                if value {
                    openCircularWindow()
                }
            }
            .store(in: &cancellables)
        
        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { event in
            guard let window = circularWindow else { return }

            let mouseLocation = NSEvent.mouseLocation
            let windowFrame = window.frame

            if !windowFrame.contains(mouseLocation) {
                circularWindow?.close()
                circularWindow = nil
            }
        }
        viewModel.connectionManager.listenerAdded = true
    }
    
    @ViewBuilder
    private func pageNumberView(page: Int) -> some View {
        HStack {
            VStack(alignment: .trailing) {
                Text("Page \(page)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.white)
                if viewModel.getAssigned(to: page) != nil {
                    Text("Assigned to: ")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color.gray)
                }
            }
            if let assignedApp = viewModel.getAssigned(to: page) {
                if let data = viewModel.getIcon(fromAppPath: assignedApp.appPath),
                   let image = NSImage(data: data) {
                    VStack {
                        ZStack {
                            Image(nsImage: image)
                                .resizable()
                                .scaledToFill()
                                .cornerRadius(cornerRadius)
                                .frame(width: 70, height: 70)
                                .padding(.bottom, 4.0)
                            VStack {
                                HStack {
                                    Spacer()
                                    RedXButton {
                                        viewModel.unassign(app: assignedApp.appPath, from: page)
                                    }
                                }
                                Spacer()
                            }
                        }
                    }
                    .frame(width: 70, height: 70)
                    .onDrop(of: [.text], isTargeted: nil) { providers in
                        providers.first?.loadObject(ofClass: NSString.self) { (droppedItem, _) in
                            if let droppedString = droppedItem as? String,
                               let object = viewModel.app(for: droppedString),
                               let path = object.path {
                                DispatchQueue.main.async {
                                    viewModel.replace(app: path, to: page)
                                }
                            }
                        }
                        return true
                    }
                }
            } else {
                Button("Assign") {
                    if let path = selectApp() {
                        viewModel.assign(app: path, to: page)
                    }
                }
                .onDrop(of: [.text], isTargeted: nil) { providers in
                    providers.first?.loadObject(ofClass: NSString.self) { (droppedItem, _) in
                        if let droppedString = droppedItem as? String,
                           let object = viewModel.app(for: droppedString),
                           let path = object.path {
                            DispatchQueue.main.async {
                                viewModel.assign(app: path, to: page)
                            }
                        }
                    }
                    return true
                }
            }
        }
        .padding()
        .background(
            RoundedBackgroundView()
        )
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
                    ), page: page
            )
        }
    }

    private func positionWindowAtMouse(window: NSWindow?, size: CGFloat) {
        guard let window else {
            return
        }
        let mouseLocation = NSEvent.mouseLocation

        // Flip Y-coordinate relative to that screen
        let origin = CGPoint(
            x: mouseLocation.x - size / 2,
            y: mouseLocation.y - size / 2
        )

        window.setFrameOrigin(origin)
    }
    
    @ViewBuilder
    private var pairiningView: some View {
        VStack {
            switch viewModel.connectionManager.pairingStatus {
            case .notPaired:
                if let availablePeerWithName = viewModel.connectionManager.availablePeerWithName,
                   let availablePeer = availablePeerWithName.0 {
                    BlueButton(
                        title: "Connect to \(availablePeerWithName.1)",
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
            } else if object.type == .html {
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
                                    Spacer()
                                    if let automation = viewModel.appHasAutomation(path: app.path ?? "") {
                                        Button("Automation") {
                                            openAutomationItemWindow(automation)
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .tint(.blue)
                                    }
                                    if viewModel.isAppAddedByUser(path: app.path ?? "") {
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
    
    private func openCompanionAppWindow() {
        if nil == newWindow {
            companionAppWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 600, height: 550),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            companionAppWindow?.center()
            companionAppWindow?.setFrameAutosaveName("Webpages")
            companionAppWindow?.isReleasedWhenClosed = false
            companionAppWindow?.titlebarAppearsTransparent = true
            companionAppWindow?.styleMask.insert(.fullSizeContentView)
            
            guard let visualEffect = NSVisualEffectView.createVisualAppearance(for: companionAppWindow) else {
                return
            }
            companionAppWindow?.contentView?.addSubview(visualEffect, positioned: .below, relativeTo: nil)
            let hv = NSHostingController(rootView: CompanionAppView())
            companionAppWindow?.contentView?.addSubview(hv.view)
            hv.view.frame = companionAppWindow?.contentView?.bounds ?? .zero
            hv.view.autoresizingMask = [.width, .height]
            companionAppWindow?.makeKeyAndOrderFront(nil)
            return
        }
        companionAppWindow?.contentView?.subviews.forEach { $0.removeFromSuperview() }
        let hv = NSHostingController(rootView: CompanionAppView())
        companionAppWindow?.contentView?.addSubview(hv.view)
        hv.view.frame = companionAppWindow?.contentView?.bounds ?? .zero
        hv.view.autoresizingMask = [.width, .height]
        companionAppWindow?.makeKeyAndOrderFront(nil)
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
    
    func openCircularWindow() {
        circularWindow?.close()
        circularWindow = nil
        if nil == circularWindow {
            circularWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 300, height: 300),
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            circularWindow?.center()
            circularWindow?.isReleasedWhenClosed = false
            circularWindow?.titleVisibility = .hidden
            circularWindow?.titlebarAppearsTransparent = true
            circularWindow?.isOpaque = false
            circularWindow?.backgroundColor = .clear
            circularWindow?.hasShadow = false
            circularWindow?.isMovableByWindowBackground = true
            circularWindow?.level = .floating
            let hostingController = NSHostingController(
                rootView: QuickActionsView(
                    viewModel: .init(items: viewModel.quickActionItems), action: { item in
                        viewModel.connectionManager.runShortuct(for: item)
                        circularWindow?.close()
                        circularWindow = nil
                    }
                )
            )
            circularWindow?.contentView = hostingController.view
            positionWindowAtMouse(window: circularWindow, size: 300)
            circularWindow?.makeKeyAndOrderFront(nil)
            return
        }
        circularWindow?.makeKeyAndOrderFront(nil)
    }
    
    private func openInstallAutomationsWindow() {
        if nil == automationsToInstallWindow {
            automationsToInstallWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 1100, height: 700),
                styleMask: [.titled, .closable, .miniaturizable],
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
    
    private func openCreateNewUtilityWindow() {
        newUtilityWindow?.close()
        newUtilityWindow = nil
        if nil == newUtilityWindow {
            newUtilityWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 1150, height: 500),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            newUtilityWindow?.center()
            newUtilityWindow?.setFrameAutosaveName("NewUtility")
            newUtilityWindow?.isReleasedWhenClosed = false
            newUtilityWindow?.titlebarAppearsTransparent = true
            newUtilityWindow?.styleMask.insert(.fullSizeContentView)
            
            guard let visualEffect = NSVisualEffectView.createVisualAppearance(for: newUtilityWindow) else {
                return
            }
            
            newUtilityWindow?.contentView?.addSubview(visualEffect, positioned: .below, relativeTo: nil)
            let hv = NSHostingController(rootView: SelectUtilityTypeWindowView(
                connectionManager: viewModel.connectionManager,
                categories: viewModel.allCategories(),
                delegate: viewModel,
                closeAction: {
                    newUtilityWindow?.close()
                }))
            newUtilityWindow?.contentView?.addSubview(hv.view)
            hv.view.frame = newUtilityWindow?.contentView?.bounds ?? .zero
            hv.view.autoresizingMask = [.width, .height]
        }
        newUtilityWindow?.makeKeyAndOrderFront(nil)
    }
    
    private func openQuickActionWindow() {
        quickActionSetupWindow?.close()
        quickActionSetupWindow = nil
        if nil == quickActionSetupWindow {
            quickActionSetupWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            quickActionSetupWindow?.center()
            quickActionSetupWindow?.setFrameAutosaveName("QuickActionSetupWindow")
            quickActionSetupWindow?.isReleasedWhenClosed = false
            quickActionSetupWindow?.titlebarAppearsTransparent = true
            quickActionSetupWindow?.styleMask.insert(.fullSizeContentView)
            quickActionSetupWindow?.level = .floating
            guard let visualEffect = NSVisualEffectView.createVisualAppearance(for: quickActionSetupWindow) else {
                return
            }
            
            quickActionSetupWindow?.contentView?.addSubview(visualEffect, positioned: .below, relativeTo: nil)
            let hv = NSHostingController(rootView: QuicActionMenuSetupView(
                setupViewModel: .init(
                    items: viewModel.quickActionItems,
                    allItems: viewModel.allObjects()),
                action: { items, shouldClose in
                    if let items {
                        viewModel.saveQuickActionItems(items)
                    }
                    if shouldClose {
                        quickActionSetupWindow?.close()
                    }
                })
            )
            quickActionSetupWindow?.contentView?.addSubview(hv.view)
            hv.view.frame = quickActionSetupWindow?.contentView?.bounds ?? .zero
            hv.view.autoresizingMask = [.width, .height]
        }
        quickActionSetupWindow?.makeKeyAndOrderFront(nil)
    }
    
    private func openAutomationItemWindow(_ item: AutomationItem) {
        automationItemWindow?.close()
        automationItemWindow = nil
        if nil == automationItemWindow {
            automationItemWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 700),
                styleMask: [.titled, .closable, .miniaturizable],
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
            }, close: {
                automationItemWindow?.close()
            }))
            automationItemWindow?.contentView?.addSubview(hv.view)
            hv.view.frame = automationItemWindow?.contentView?.bounds ?? .zero
            hv.view.autoresizingMask = [.width, .height]
            automationItemWindow?.makeKeyAndOrderFront(nil)
            return
        }
    }
    
    private func openEditUtilityWindow(item: ShortcutObject) {
        editUtilitiesWindow?.close()
        editUtilitiesWindow = nil
        if nil == editUtilitiesWindow {
            if item.color == .convert {
                editUtilitiesWindow = NSWindow(
                    contentRect: NSRect(x: 0, y: 0, width: 520, height: 300),
                    styleMask: [.titled, .closable, .miniaturizable],
                    backing: .buffered,
                    defer: false
                )
            } else {
                editUtilitiesWindow = NSWindow(
                    contentRect: NSRect(x: 0, y: 0, width: 520, height: 470),
                    styleMask: item.utilityType == .commandline || item.utilityType == .automation || item.utilityType == .html ? [.titled, .closable, .resizable, .miniaturizable] : [.titled, .closable, .miniaturizable],
                    backing: .buffered,
                    defer: false
                )
            }
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
                if item.color == .convert {
                    let hv = NSHostingController(rootView: ConverterView(item: item, delegate: viewModel){
                        editUtilitiesWindow?.close()
                    })
                    editUtilitiesWindow?.contentView?.addSubview(hv.view)
                    hv.view.frame = editUtilitiesWindow?.contentView?.bounds ?? .zero
                    hv.view.autoresizingMask = [.width, .height]
                } else if item.color == .raycast {
                    let hv = NSHostingController(rootView: RaycastUtilityView(item: item, delegate: viewModel){
                        editUtilitiesWindow?.close()
                    })
                    editUtilitiesWindow?.contentView?.addSubview(hv.view)
                    hv.view.frame = editUtilitiesWindow?.contentView?.bounds ?? .zero
                    hv.view.autoresizingMask = [.width, .height]
                } else {
                    let hv = NSHostingController(rootView: NewBashUtilityView(categories: viewModel.allCategories(), item: item, delegate: viewModel) {
                        editUtilitiesWindow?.close()
                    })
                    editUtilitiesWindow?.contentView?.addSubview(hv.view)
                    hv.view.frame = editUtilitiesWindow?.contentView?.bounds ?? .zero
                    hv.view.autoresizingMask = [.width, .height]
                }
            case .html:
                let hv = NSHostingController(rootView: HTMLUtilityView(categories: viewModel.allCategories(), item: item, delegate: viewModel) {
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

import QRCode

struct CompanionAppView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("Get the Companion App")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Scan the QR code below to download the iOS / iPadOS companion app from the App Store.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            if let image = generateQRCode() {
                Text("Scan to connect")
                Image(nsImage: image)
                    .resizable()
                    .frame(width: 200, height: 200)
            }

            Text("Or search for “MobilityControl” on the App Store.")
                .font(.footnote)
                .foregroundColor(.gray)
        }
        .padding()
    }
    
    func generateQRCode() -> NSImage? {
        let doc = QRCode.Document(utf8String: "https://apps.apple.com/pl/app/mobilitycontrol/id6744455092",
                                  errorCorrection: .high)
        guard let generated = doc.cgImage(CGSize(width: 800, height: 800)) else { return nil }
        return NSImage(cgImage: generated, size: .init(width: 200, height: 200))
    }
}
