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
    
    var backgroundColor: Color {
        switch self {
        case .notConnected:
            return .clear
        case .connected, .connecting, .disconnecting:
            return .disconnection
        }
    }
}

struct DraggingData {
    let size: CGSize?
    var indexes: [Int]?
}

struct ShortcutsView: View {
    @StateObject var responder = HotKeyResponder.shared
    @ObservedObject var viewModel: ShortcutsViewModel
    @State var newWindow: NSWindow?
    @State var newUtilityWindow: NSWindow?
    @State var shortcutsToInstallWindow: NSWindow?
    @State var automationsToInstallWindow: NSWindow?
    @State var automationItemWindow: NSWindow?
    @State var editUtilitiesWindow: NSWindow?
    @State var companionAppWindow: NSWindow?
    @State var uiControlAppWindow: NSWindow?
    @State var uiControlListAppWindow: NSWindow?
    @State var quickActionSetupWindow: NSWindow?
    @State var uiControlCreateWindow: NSWindow?
    @State var shouldShowCompanionRequestPopup: Bool = false
    @State var selectedTab = 0
    @State var tab: Tab = .apps
    
    @State var resolutions: [DisplayMode] = []
    @State var selectedMode: DisplayMode?
    @State var cancellables = Set<AnyCancellable>()
    
    let testSize = 7.0

    @Namespace var animation
    let cornerRadius = 17.0
    
    init(viewModel: ShortcutsViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                pairiningView
                menuView
            }
            .padding([.horizontal, .top], 16)
            .padding(.bottom, 8.0)
            .animation(.easeInOut, value: viewModel.pairingStatus)
            Divider()
        }
        .padding(.top, 21.0)
        .frame(minWidth: 1300.0)
        HStack(alignment: .top) {
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
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 70), alignment: .leading)], spacing: 10) {
                                ForEach(0..<21) { index in
                                    mainItemView(index: index, page: page)
                                    .if(viewModel.shouldDisplayPlusAt(index: index, page: page) == nil) {
                                        $0
                                            .frame(width: 70, height: 70)
                                            .background(
                                                plusView(index: index, page: page)
                                            )
                                    }
                                    .if(viewModel.shouldDisplayPlusAt(index: index, page: page) != nil) {
                                        $0
                                            .frame(width: 70, height: 70)
                                            .if(viewModel.draggingData.size == nil) {
                                                $0.background(
                                                    EmptyView()
                                                )
                                            }
                                            .if(viewModel.draggingData.size != nil) {
                                                $0.background(
                                                    plusView(index: index, page: page)
                                                        .opacity(0.01)
                                                )
                                            }
                                    }
                                    .ifLet(viewModel.objectAt(index: index, page: page)?.id) { view, id in
                                        view.onDrag {
                                            NSItemProvider(object: id as NSString)
                                        }
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
                    .onChange(of: viewModel.pairingStatus) { _, newValue in
                        if newValue == .notPaired {
                            viewModel.connectionManager.stopTCPServer { success in
                                print("Disconnected from server: \(success)")
                            }
                            viewModel.streamConnectionState = .notConnected
                        }
                    }
                    VStack {
                        BlueButton(
                            title: "New Page",
                            font: .callout,
                            padding: 8.0,
                            cornerRadius: 6.0,
                            leadingImage: "plus.rectangle.on.rectangle",
                            backgroundColor: .clear
                        ) {
                            viewModel.addPage()
                        }
                        .padding(.bottom, 45.0)
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
    
    @ViewBuilder
    var menuView: some View {
        switch viewModel.streamConnectionState {
        case .connected, .notConnected:
            BlueButton(
                title: viewModel.streamConnectionState.label,
                font: .callout,
                padding: 8.0,
                cornerRadius: 6.0,
                leadingImage: "rectangle.on.rectangle",
                backgroundColor: viewModel.streamConnectionState.backgroundColor
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
            .disabled(viewModel.pairingStatus != .paired)
            .padding(.all, 3.0)
        case .connecting:
            BlueButton(
                title: "Connecting...",
                font: .callout,
                padding: 8.0,
                cornerRadius: 6.0,
                leadingImage: "rectangle.on.rectangle",
                backgroundColor: .disconnection
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
                leadingImage: "rectangle.on.rectangle",
                backgroundColor: .disconnection
            ) {
            }
            .padding(.all, 3.0)
        }
        
        Divider()
            .frame(height: 14.0)
        
        BlueButton(
            title: "Store",
            font: .callout,
            padding: 8.0,
            cornerRadius: 6.0,
            leadingImage: "storefront.circle",
            backgroundColor: .clear
        ) {
            openInstallAutomationsWindow()
        }
        .padding(.all, 3.0)
        
        Divider()
            .frame(height: 14.0)
        
        BlueButton(
            title: "Add URL",
            font: .callout,
            padding: 8.0,
            cornerRadius: 6.0,
            leadingImage: "link.badge.plus",
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
            leadingImage: "plus.app",
            backgroundColor: .clear
        ) {
            openCreateNewUtilityWindow()
        }
        .padding(.all, 3.0)
        
        BlueButton(
            title: "UI Controls",
            font: .callout,
            padding: 8.0,
            cornerRadius: 6.0,
            leadingImage: "plus.app",
            backgroundColor: .clear
        ) {
            openUIControlAppWindow()
        }
        .padding(.all, 3.0)
        
        Spacer()
        AnimatedSearchBar(searchText: $viewModel.searchText)
            .padding(.all, 3.0)
        BlueButton(
            title: "",
            font: .callout,
            padding: 8.0,
            cornerRadius: 6.0,
            leadingImage: "qrcode",
            backgroundColor: .clear
        ) {
            openCompanionAppWindow()
        }
        .padding(.all, 3.0)
    }
    
    @ViewBuilder
    func plusView(index: Int, page: Int) -> some View {
        PlusButtonView(index: index, page: page, affectedIndexes: $viewModel.affectedIndexes, dropAction: { droppedItem in
            if let droppedString = droppedItem as? String,
               let object = viewModel.object(for: droppedString, index: index, page: page) {
                handleOnDrop(index: index, page: page, object: object)
            } else {
                DispatchQueue.main.async {
                    self.viewModel.draggingData = .init(size: nil)
                    self.viewModel.currentlyTargetedIndex = nil
                    self.viewModel.affectedIndexes = .init(page: -1, indexes: [], conflict: false)
                }
            }
        }) { currentIndex, isTargeting in
            if isTargeting {
                viewModel.currentlyTargetedIndex = .init(page: page, index: currentIndex)
            } else {
                viewModel.currentlyTargetedIndex = nil
                viewModel.affectedIndexes = .init(page: -1, indexes: [], conflict: false)
            }
        }
    }
    
    @ViewBuilder
    func dragView<Content: View>(_ view: Content, object: ShortcutObject) -> some View {
        switch object.type {
        case .control:
            view.onDrag {
                viewModel.draggingData = .init(size: object.size, indexes: object.indexes)
                return NSItemProvider(object: object.id as NSString)
            } preview: {
                RoundedRectangle(cornerRadius: 5.0)
                    .fill(Color.blue)
                    .frame(
                        width: 20 * (object.size?.width ?? 1) + testSize * (object.size?.width ?? 1),
                        height: 20 * (object.size?.height ?? 1) + testSize * (object.size?.height ?? 1)
                    )
            }
        default:
            view.onDrag {
                return NSItemProvider(object: object.id as NSString)
            }
        }
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
    
    func handleOnDrop(index: Int, page: Int, object: ShortcutObject) {
        DispatchQueue.main.async {
            viewModel.draggingData = .init(size: nil)
            viewModel.affectedIndexes = .init(page: -1, indexes: [], conflict: false)
            viewModel.currentlyTargetedIndex = nil
            viewModel.addConfiguredShortcut(object:
                    .init(
                        type: object.type,
                        page: page,
                        index: index,
                        indexes: neighboringIndexes(for: index, size: object.size ?? .init(width: 1, height: 1)),
                        size: object.size ?? .init(width: 1, height: 1),
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
    
    func neighboringIndexes(for index: Int, size: CGSize, inGridWithColumns columns: Int = 7, rows: Int = 3) -> [Int]? {
        let totalSquares = columns * rows
        let objectWidth = Int(size.width)
        let objectHeight = Int(size.height)

        let startRow = index / columns
        let startCol = index % columns

        // Check if the object would go out of bounds
        if startCol + objectWidth > columns || startRow + objectHeight > rows {
            return nil
        }

        var result: [Int] = []

        for dy in 0..<objectHeight {
            for dx in 0..<objectWidth {
                let newRow = startRow + dy
                let newCol = startCol + dx
                let newIndex = newRow * columns + newCol

                // Additional safety check
                if newIndex < totalSquares {
                    result.append(newIndex)
                } else {
                    return nil
                }
            }
        }

        return result
    }
    
    @ViewBuilder
    private var pairiningView: some View {
        VStack {
            switch viewModel.pairingStatus {
            case .notPaired:
                if let availablePeerWithName = viewModel.availablePeerWithName,
                   let availablePeer = availablePeerWithName.0 {
                    BlueButton(
                        title: "Connect to \(availablePeerWithName.1)",
                        font: .callout,
                        padding: 10.0,
                        cornerRadius: 6.0,
                        leadingImage: "app.connected.to.app.below.fill",
                        backgroundColor: .accentColor
                    ) {
                        viewModel.connectionManager.invitePeer(with: availablePeer)
                        viewModel.pairingStatus = .pairining
                    }
                    .padding(.all, 3.0)
                }
            case .paired:
                BlueButton(
                    title: "Disconnect from \(viewModel.connectedPeerName ?? "")",
                    font: .callout,
                    padding: 8.0,
                    cornerRadius: 6.0,
                    leadingImage: "app.connected.to.app.below.fill",
                    backgroundColor: .disconnection
                ) {
                    viewModel.connectionManager.disconnect()
                    viewModel.pairingStatus = .notPaired
                }
                .padding(.all, 3.0)
            case .pairining:
                BlueButton(
                    title: "Cancel pairing",
                    font: .callout,
                    padding: 8.0,
                    cornerRadius: 6.0,
                    leadingImage: "app.connected.to.app.below.fill",
                    backgroundColor: .disconnection
                ) {
                    viewModel.connectionManager.cancel()
                }
                .padding(.all, 3.0)
            }
        }
        .animation(.easeInOut, value: viewModel.pairingStatus)
    }
    
    @ViewBuilder
    func itemViews(for index: Int, page: Int, size: CGSize) -> some View {
        if let object = viewModel.objectAt(index: index, page: page) {
            if let path = object.path, object.type == .app {
                Image(nsImage: NSWorkspace.shared.icon(forFile: path))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.width, height: size.height)
            } else if object.type == .shortcut {
                if let data = object.imageData, let image = NSImage(data: data) {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                        .cornerRadius(cornerRadius)
                        .frame(width: size.width, height: size.height)
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
                        .frame(width: size.width, height: size.height)
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
                        .frame(width: size.width, height: size.height)
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
                        .frame(width: size.width, height: size.height)
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
                            .frame(maxWidth: 80 * (object.size?.width ?? 1))
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
            } else if object.type == .control {
                if object.path == "control:horizontal-slider" {
                    BrightnessVolumeContainerView()
                        .frame(width: size.width, height: size.height)
                } else if object.path == "control:rotary-knob" {
                    RotaryKnobIcon()
                        .frame(width: size.width, height: size.height)
                } else {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.blue)
                        .frame(width: size.width, height: size.height)
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
}
