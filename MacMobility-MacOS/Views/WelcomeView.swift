//
//  WelcomeView.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 19/04/2025.
//

import SwiftUI
import QRCode
import AppKit
import SwiftUI
import AVKit

struct WebsiteTest {
    let id: String
    let nsImage: NSImage?
    var url: String
}

class WelcomeViewModel: ObservableObject {
    @Published var currentPage = 0
    let pageLimit = 7
    let closeAction: (SetupMode?, [AutomationOption]?, [WebsiteTest], Bool, Browsers) -> Void
    private(set) var createMultiactions: Bool = true
    private(set) var setupMode: SetupMode?
    private(set) var automationOptions: [AutomationOption]?
    private(set) var favoriteBrowser: Browsers = .safari
    private(set) var websites: [WebsiteTest] = [
        .init(id: UUID().uuidString, nsImage: nil, url: ""),
        .init(id: UUID().uuidString, nsImage: nil, url: ""),
        .init(id: UUID().uuidString, nsImage: nil, url: "")
    ]
    
    init(closeAction: @escaping (SetupMode?, [AutomationOption]?, [WebsiteTest], Bool, Browsers) -> Void) {
        self.closeAction = closeAction
    }
    
    func nextPage() {
        if currentPage < pageLimit {
            currentPage += 1
        }
    }
    
    func previousPage() {
        currentPage = max(0, currentPage - 1)
    }
    
    func close() {
        closeAction(setupMode, automationOptions, websites, createMultiactions, favoriteBrowser)
    }
    
    func updateSetupMode(_ setupMode: SetupMode) {
        self.setupMode = setupMode
    }
    
    func updateAutomationOptions(_ automationOptions: [AutomationOption]) {
        self.automationOptions = automationOptions
    }
    
    func updateWebsite(_ website: WebsiteTest) {
        if let index = websites.firstIndex(where: { $0.id == website.id }) {
            websites[index] = website
        }
    }
    
    func updateURL(for id: String, url: String) {
        if let index = websites.firstIndex(where: { $0.id == id }) {
            websites[index].url = url
        }
    }
    
    func updateMultiaction(_ createMultiactions: Bool) {
        self.createMultiactions = createMultiactions
    }
    
    func updateBrowser(_ browser: Browsers) {
        self.favoriteBrowser = browser
    }
}

struct WelcomeView: View {
    @ObservedObject private var viewModel: WelcomeViewModel
    @State private var showWelcomeText = false
    @State private var scaleEffect: CGFloat = 0.8
    @State private var showSkipAlert: Bool = false
    private let connectionManager: ConnectionManager
    
    init(viewModel: WelcomeViewModel, connectionManager: ConnectionManager) {
        self.viewModel = viewModel
        self.connectionManager = connectionManager
    }
    
    public var body: some View {
        VStack {
            Group {
                switch viewModel.currentPage {
                case 0:
                    titlePageView
                case 1:
                    companionAppView
                case 2:
                    OnboardingVideoComparisonView()
                case 3:
                    PermissionView(viewModel: .init(connectionManager: connectionManager))
                case 4:
                    AppSetupChoiceView(viewModel.setupMode) { setupMode in
                        viewModel.updateSetupMode(setupMode)
                    }
                case 5:
                    AutodetectAutomationInstallView(viewModel: .init(viewModel.automationOptions) { options in
                        viewModel.updateAutomationOptions(options)
                    })
                case 6:
                    PredefinedWebsitesCreationView(viewModel: .init(
                        websiteOne: viewModel.websites[0],
                        webstiteTwo: viewModel.websites[1],
                        websiteThree: viewModel.websites[2],
                        createMultiactions: viewModel.createMultiactions,
                        browser: viewModel.favoriteBrowser)) { website in
                            viewModel.updateWebsite(website)
                        } urlUpdate: { id, url in
                            viewModel.updateURL(for: id, url: url)
                        } createMultiactions: { value in
                            viewModel.updateMultiaction(value)
                        } browser: { browser in
                            viewModel.updateBrowser(browser)
                        }
                case 7:
                    FinalScreenView {
                        viewModel.close()
                    }
                default:
                    EmptyView()
                }
            }
            .frame(height: 400)
            if showWelcomeText {
                PageIndicatorView(numberOfPages: viewModel.pageLimit + 1, currentPage: viewModel.currentPage)
                    .padding()
            }
                
            if showWelcomeText {
                HStack {
                    Spacer()
                    Spacer()
                        .frame(width: 30.0)
                    if viewModel.currentPage > 0 {
                        Button("Previous") {
                            self.viewModel.previousPage()
                        }
                    }
                    if viewModel.currentPage < viewModel.pageLimit {
                        Button("Next") {
                            self.viewModel.nextPage()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                    }
                    Spacer()
                    Button("Skip") {
                        self.showSkipAlert = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
                .padding()
            }
        }
        .alert("Skip Onboarding?", isPresented: $showSkipAlert) {
            Button("Continue Onboarding", role: .none) {
                showSkipAlert = false
            }
            Button("Skip", role: .cancel) {
                showSkipAlert = false
                self.viewModel.close()
            }
        } message: {
            Text("Are you sure you want to skip onboarding? You might miss important setup information.")
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 5)) {
                showWelcomeText = true
            }
            for window in NSApplication.shared.windows {
                window.appearance = NSAppearance(named: .darkAqua)
            }
        }
        .padding(.horizontal, 21.0)
    }
    
    private var titlePageView: some View {
        VStack {
            Image(.logo)
                .resizable()
                .frame(width: 256, height: 256)
                .cornerRadius(20)
                .padding(.bottom, 12.0)
                .scaleEffect(scaleEffect)
                .animation(.spring(duration: 5, bounce: 0, blendDuration: 1), value: scaleEffect)
                .onAppear {
                    scaleEffect = 1.0
                }
            if showWelcomeText {
                Text("MacMobility")
                    .font(.system(size: 28, weight: .bold))
                    .padding(.bottom, 6.0)
                Text("Ultimate productivity tool for MacOS!")
                    .foregroundStyle(Color.gray)
                    .padding(.bottom, 6.0)
            }
        }
        .padding()
    }
    
    private var secondPage: some View {
        VStack(spacing: 24) {
            Image(.logo) // Replace with your actual app icon image name
                .resizable()
                .frame(width: 100, height: 100)
                .cornerRadius(20)
                .shadow(radius: 8)
            
            VStack(alignment: .center, spacing: 12) {
                Text("Seamless Control")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("With MacMobility, you can launch apps, run shortcuts, and trigger automations wirelessly from your iPhone or iPad. It’s your Mac, more mobile than ever.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
    
    private var companionAppView: some View {
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

struct OnboardingVideoComparisonView: View {
    private let leftPlayer = AVQueuePlayer()
    private let rightPlayer = AVQueuePlayer()

    init() {
        setupLoopingVideo(player: leftPlayer, resource: "ipad-connect")
        setupLoopingVideo(player: rightPlayer, resource: "mac-connect")
    }

    var body: some View {
        VStack(spacing: 32) {
            Text("How to connect Macbook to mobile device")
                .font(.title)
                .fontWeight(.bold)

            Text("After downloading the app on mobile device, you can now connect your Macbook to your device using the following methods.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            HStack(spacing: 24) {
                VideoPreviewView(player: leftPlayer, title: "From mobile device", description: "If app on Macbook is already open, you can connect your device to Macbook using the Connect button from the mobile device.")

                VideoPreviewView(player: rightPlayer, title: "From Macbook", description: "Open the app on Macbook and select the device you want to connect with.")
            }
            .frame(height: 240)
        }
        .padding()
        .onAppear {
            leftPlayer.play()
            rightPlayer.play()
        }
    }

    private func setupLoopingVideo(player: AVQueuePlayer, resource: String) {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "mp4") else { return }
        let item = AVPlayerItem(url: url)
        player.insert(item, after: nil)
        player.actionAtItemEnd = .none

        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main) { _ in
            player.seek(to: .zero)
            player.play()
        }
    }
}

struct AVPlayerViewNoControls: NSViewRepresentable {
    let player: AVPlayer

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspect
        playerLayer.isHidden = false
        playerLayer.needsDisplayOnBoundsChange = true
        view.layer = playerLayer
        view.wantsLayer = true
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        (nsView.layer as? AVPlayerLayer)?.player = player
    }
}

struct VideoPreviewView: View {
    let player: AVPlayer
    let title: String
    let description: String

    var body: some View {
        VStack(spacing: 12) {
            AVPlayerViewNoControls(player: player)
                .disabled(true)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                .frame(height: 200)

            Text(title)
                .font(.headline)

            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
    }
}

struct PageIndicatorView: View {
    let numberOfPages: Int
    let currentPage: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<numberOfPages, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Color.accentColor : Color.gray.opacity(0.3))
                    .frame(width: index == currentPage ? 12 : 8,
                           height: index == currentPage ? 12 : 8)
                    .animation(.easeInOut(duration: 0.2), value: currentPage)
            }
        }
    }
}

enum SetupModeType {
    case basic
    case advanced
}

struct SetupMode: Identifiable, Equatable {
    let id: UUID = UUID()
    let title: String
    let description: String
    let imageName: String
    let type: SetupModeType
    
    static func ==(lhs: SetupMode, rhs: SetupMode) -> Bool {
        lhs.imageName == rhs.imageName && lhs.title == rhs.title && lhs.description == rhs.description
    }
}

struct AppSetupChoiceView: View {
    @State private var selectedMode: String = "prepared"
    private let action: (SetupMode) -> Void
    
    let options: [SetupMode] = [
        SetupMode(title: "Start with Advanced Actions",
                  description: "Get started quickly with a few more adcanced automations, scripts and actions already set up for you.",
                  imageName: "sparkles",
                  type: .advanced),
        
        SetupMode(title: "Start Basic",
                  description: "Start with some basic automations and scripts to get you up and running.",
                  imageName: "square.dashed",
                  type: .basic)
    ]
    
    init(_ setupMode: SetupMode?, action: @escaping (SetupMode) -> Void) {
        if let setupMode {
            self.selectedMode = setupMode == options.first ? "prepared" : "blank"
        } else {
            action(options[0])
        }
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 32) {
            Text("How would you like to start?")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Choose a setup style to begin using MacMobility. You can always customize everything later.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            HStack(spacing: 24) {
                ForEach(options.indices, id: \.self) { index in
                    let mode = options[index]
                    let isSelected = (selectedMode == "prepared" && index == 0) || (selectedMode == "blank" && index == 1)
                    
                    VStack(spacing: 12) {
                        Image(systemName: mode.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundColor(isSelected ? .blue : .gray)

                        Text(mode.title)
                            .font(.headline)

                        Text(mode.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 3 : 1)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
                            )
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedMode = (index == 0) ? "prepared" : "blank"
                        action(options[index])
                    }
                }
            }
        }
        .padding()
    }
}


struct AutomationOption: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let imageName: String?
    let imageData: Data?
    var scripts: [AutomationScript]
    var isSelected: Bool = true
    var isOptional: Bool = true
}

class AutodetectAutomationInstallViewModel: ObservableObject, JSONLoadable {
    @Published var options: [AutomationOption] = [
        .init(title: "macOS System",
              description: "Essential system-level automations to help you work faster on your Mac.",
              imageName: "gearshape",
              imageData: nil,
              scripts: [],
              isOptional: false)
    ]
    
    var updateAction: ([AutomationOption]) -> Void
    
    init(_ options: [AutomationOption]?, updateAction: @escaping ([AutomationOption]) -> Void) {
        self.updateAction = updateAction
        if let options {
            self.options = options
        } else {
            fetchInstalledApps(isInitial: true)
        }
    }
    
    func fetchInstalledApps(isInitial: Bool = false) {
        let appDirectories = [
            "/Applications",
            "/System/Applications/Utilities"
        ]

        var apps: [String] = []

        for directory in appDirectories {
            apps.append(contentsOf: findApps(in: directory))
        }
        
        let automations: AutomationsList = loadJSON("automations")
        if let macOsAutomations = automations.automations.first(where: { $0.title == "MacOS" }) {
            options[0].scripts = macOsAutomations.scripts
        }
        automations.automations.forEach { automation in
            if apps.contains(where: { $0 == automation.title }) {
                options.append(.init(title: automation.title,
                                     description: automation.description,
                                     imageName: nil,
                                     imageData: automation.imageData,
                                     scripts: automation.scripts))
            }
        }
        if isInitial {
            updateAction(options)
        }
    }
    
    func findApps(in directory: String) -> [String] {
        var apps: [String] = []

        if let appURLs = try? FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: directory), includingPropertiesForKeys: nil, options: .skipsHiddenFiles) {
            for appURL in appURLs where appURL.pathExtension == "app" {
                let appName = appURL.deletingPathExtension().lastPathComponent
                apps.append(appName)
            }
        }

        return apps
    }
    
    func updateMainModel() {
        self.updateAction(self.options)
    }
}

struct AutodetectAutomationInstallView: View {
    @ObservedObject private var viewModel: AutodetectAutomationInstallViewModel
    @State private var allSelected: Bool = true
    
    init(viewModel: AutodetectAutomationInstallViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Install Recommended Automations?")
                    .font(.title)
                    .fontWeight(.bold)

                Text("We’ve detected some apps you use and prepared automations for them. You can choose which ones to install now. Don’t worry — you can add or remove these later.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            VStack(spacing: 16) {
                HStack {
                    Spacer()
                    Text(allSelected ? "Deselect All" : "Select All")
                    Toggle("", isOn: $allSelected)
                        .onChange(of: allSelected) { _, newValue in
                            for index in viewModel.options.indices {
                                viewModel.options[index].isSelected = newValue
                            }
                        }
                        .toggleStyle(.switch)
                        .labelsHidden()
                }
                .padding(.trailing, 16.0)
                ScrollView {
                    ForEach($viewModel.options) { $option in
                        HStack(spacing: 16) {
                            if let imageName = option.imageName {
                                Image(systemName: imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(.blue)
                            } else if let data = option.imageData, let image = NSImage(data: data) {
                                Image(nsImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .cornerRadius(10.0)
                                    .frame(width: 40, height: 40)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(option.title)
                                    .font(.headline)
                                
                                Text(option.description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if option.isOptional {
                                Toggle("", isOn: $option.isSelected)
                                    .toggleStyle(.switch)
                                    .labelsHidden()
                                    .onChange(of: option.isSelected) { _, _ in
                                        viewModel.updateMainModel()
                                    }
                            } else {
                                Text("Required")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.gray)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.controlBackgroundColor))
                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            option.isSelected.toggle()
                            updateMasterToggleState()
                        }
                    }
                }
            }
        }
        .padding()
    }
    
    private func updateMasterToggleState() {
        allSelected = viewModel.options.allSatisfy { $0.isSelected }
    }
}

struct FinalScreenView: View {
    @State private var showButton = false
    @State private var scaleEffect: CGFloat = 0.8
    
    let closeAction: () -> Void
    
    init(closeAction: @escaping () -> Void) {
        self.closeAction = closeAction
    }
    
    var body: some View {
        VStack(spacing: 30) {
            Text("That's all, let's start!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .opacity(0.9)
                .scaleEffect(scaleEffect)
                .animation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0.5), value: scaleEffect)
                .onAppear {
                    scaleEffect = 1.0
                }
            
            Text("You've completed the setup and are ready to start using the app!")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                        
            if showButton {
                BlueButton(title: "Let's Start", font: .title2) {
                    closeAction()
                }
                .padding(.top, 24.0)
                .frame(width: 200.0)
            }
        }
        .padding()
        .onAppear {
            withAnimation(.easeInOut(duration: 1)) {
                showButton = true
            }
        }
    }
}

struct BlueButton: View {
    let title: String
    let font: Font
    let padding: CGFloat
    let cornerRadius: CGFloat
    let leadingImage: String?
    let backgroundColor: Color
    let closeAction: () -> Void
    
    init(
        title: String,
        font: Font,
        padding: CGFloat = 16.0,
        cornerRadius: CGFloat = 10.0,
        leadingImage: String? = nil,
        backgroundColor: Color = .accentColor,
        closeAction: @escaping () -> Void
    ) {
        self.title = title
        self.font = font
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.leadingImage = leadingImage
        self.backgroundColor = backgroundColor
        self.closeAction = closeAction
    }
    
    var body: some View {
        Button(action: {
            closeAction()
        }) {
            HStack {
                if let leadingImage {
                    Image(systemName: leadingImage)
                        .resizable()
                        .frame(width: 18, height: 18)
                        .padding(.trailing, 6.0)
                }
                Text(title)
                    .font(font)
                    .fontWeight(.semibold)
                    .if(leadingImage != nil) {
                        $0.padding(.trailing, 6.0)
                    }
            }
            .padding(.all, padding)
            .background(backgroundColor)
            .foregroundColor(.white)
            .cornerRadius(cornerRadius)
            .shadow(radius: 5)
        }
        .buttonStyle(PlainButtonStyle())
        .transition(.opacity)
    }
}

enum Tab: Int, CaseIterable {
    case apps, shortcuts, webpages, utilities

    var title: String {
        switch self {
        case .apps: return "Apps"
        case .shortcuts: return "Shortcuts"
        case .webpages: return "Webpages"
        case .utilities: return "Utilities"
        }
    }

    var icon: String {
        switch self {
        case .apps: return "app"
        case .shortcuts: return "square.and.arrow.down.on.square.fill"
        case .webpages: return "link"
        case .utilities: return "text.and.command.macwindow"
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Tab
    var animation: Namespace.ID
    var didSwitch: () -> Void
    
    init(selectedTab: Binding<Tab>, animation: Namespace.ID, didSwitch: @escaping () -> Void) {
        self._selectedTab = selectedTab
        self.animation = animation
        self.didSwitch = didSwitch
    }

    var body: some View {
        HStack(spacing: 16) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        selectedTab = tab
                        didSwitch()
                    }
                }) {
                    HStack {
                        Image(systemName: tab.icon)
                            .imageScale(.medium)
                        Text(tab.title)
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundStyle(selectedTab == tab ? .white : .primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                    .background(
                        ZStack {
                            if selectedTab == tab {
                                Capsule()
                                    .fill(Color.accentColor)
                                    .matchedGeometryEffect(id: "tabBackground", in: animation)
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
        )
        .padding(.horizontal)
    }
}

import SwiftUI

struct AnimatedSearchBar: View {
    @State private var isExpanded = false
    @Binding private var searchText: String
    @FocusState private var isFocused: Bool
    
    init(searchText: Binding<String>) {
        self._searchText = searchText
    }

    var body: some View {
        HStack(spacing: 8) {
            if isExpanded {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    TextField("Search...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .focused($isFocused)
                        .frame(minWidth: 100, maxWidth: 400.0)

                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            searchText = ""
                            isExpanded = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .transition(.scale)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(nsColor: .quaternaryLabelColor)))
                .transition(.move(edge: .trailing).combined(with: .opacity))
                .onAppear {
                    isFocused = true
                }
            } else {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isExpanded = true
                    }
                }) {
                    Image(systemName: "magnifyingglass")
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(nsColor: .quaternaryLabelColor)))
                }
                .buttonStyle(.plain)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isExpanded)
    }
}

struct PlusButtonView: View {
    var size: CGSize
    
    init(size: CGSize = .init(width: 70, height: 70)) {
        self.size = size
    }
    
    var body: some View {
        let backgroundColor = Color(.sRGB, red: 0.1, green: 0.1, blue: 0.1, opacity: 1)
        let accentColor = Color(.sRGB, red: 0.3, green: 0.3, blue: 0.3, opacity: 1)

        return ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(backgroundColor)

            Image(systemName: "plus")
                .foregroundColor(accentColor)
                .font(.system(size: 20, weight: .bold))
        }
        .frame(width: size.width, height: size.height)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(accentColor, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.4), radius: 4, x: 0, y: 2)
    }
}

struct RoundedBackgroundView: View {
    var size: CGSize
    
    init(size: CGSize = .init(width: 70, height: 70)) {
        self.size = size
    }
    
    var body: some View {
        let backgroundColor = Color(.sRGB, red: 0.1, green: 0.1, blue: 0.1, opacity: 1)
        let accentColor = Color(.sRGB, red: 0.3, green: 0.3, blue: 0.3, opacity: 1)

        return ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(backgroundColor)
        }
//        .frame(width: size.width, height: size.height)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(accentColor, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.4), radius: 4, x: 0, y: 2)
    }
}

class PredefinedWebsitesCreationViewModel: ObservableObject {
    @Published var firstLink: String = ""
    @Published var secondLink: String = ""
    @Published var thirdLink: String = ""
    @Published var selectedIcon: NSImage?
    @Published var selectedIconTwo: NSImage?
    @Published var selectedIconThree: NSImage?
    @Published var createMultiactions: Bool
    @Published var selectedBrowser: Browsers
    var savedIcon: NSImage?
    var savedIconTwo: NSImage?
    var savedIconThree: NSImage?
    var idOne: String
    var idTwo: String
    var idThree: String
    
    init(websiteOne: WebsiteTest, webstiteTwo: WebsiteTest, websiteThree: WebsiteTest, createMultiactions: Bool, browser: Browsers) {
        self.firstLink = websiteOne.url
        self.secondLink = webstiteTwo.url
        self.thirdLink = websiteThree.url
        self.selectedIcon = websiteOne.nsImage
        self.selectedIconTwo = webstiteTwo.nsImage
        self.selectedIconThree = websiteThree.nsImage
        self.savedIcon = websiteOne.nsImage
        self.savedIconTwo = webstiteTwo.nsImage
        self.savedIconThree = websiteThree.nsImage
        self.idOne = websiteOne.id
        self.idTwo = webstiteTwo.id
        self.idThree = websiteThree.id
        self.createMultiactions = createMultiactions
        self.selectedBrowser = browser
    }
}

struct PredefinedWebsitesCreationView: View {
    @ObservedObject var viewModel: PredefinedWebsitesCreationViewModel
    
    var action: (WebsiteTest) -> Void
    var urlUpdate: (String, String) -> Void
    var createMultiactions: (Bool) -> Void
    var browser: (Browsers) -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Text("Do you have your favourite websites?")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Add urls of your three favourite websites here. Those will appar in yor workspace!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            HStack {
                Text("Link")
                    .font(.system(size: 14, weight: .regular))
                    .padding(.trailing, 20.0)
                RoundedTextField(placeholder: "", text: $viewModel.firstLink)
                IconPickerView(viewModel: .init(
                    selectedImage: viewModel.selectedIcon ?? viewModel.savedIcon,
                    shouldAutofetchImage: viewModel.selectedIcon == nil,
                    searchText: viewModel.firstLink,
                    completion: { image in
                        viewModel.savedIcon = image
                        action(.init(id: viewModel.idOne, nsImage: viewModel.selectedIcon ?? image, url: viewModel.firstLink))
                    }), userSelectedIcon: $viewModel.selectedIcon, imageSize: .init(width: 50.0, height: 50.0)
                )
            }
            .frame(maxWidth: .infinity)
            .onChange(of: viewModel.selectedIcon) { oldValue, newValue in
                action(.init(id: viewModel.idOne, nsImage: newValue, url: viewModel.firstLink))
            }
            .onChange(of: viewModel.firstLink) { oldValue, newValue in
                urlUpdate(viewModel.idOne, newValue)
            }
            HStack {
                Text("Link")
                    .font(.system(size: 14, weight: .regular))
                    .padding(.trailing, 20.0)
                RoundedTextField(placeholder: "", text: $viewModel.secondLink)
                IconPickerView(viewModel: .init(
                    selectedImage: viewModel.selectedIconTwo ?? viewModel.savedIconTwo,
                    shouldAutofetchImage: viewModel.selectedIconTwo == nil,
                    searchText: viewModel.secondLink,
                    completion: { image in
                        viewModel.savedIconTwo = image
                        action(.init(id: viewModel.idTwo, nsImage: image, url: viewModel.secondLink))
                    }), userSelectedIcon: $viewModel.selectedIconTwo, imageSize: .init(width: 50.0, height: 50.0)
                )
            }
            .frame(maxWidth: .infinity)
            .onChange(of: viewModel.selectedIconTwo) { oldValue, newValue in
                action(.init(id: viewModel.idTwo, nsImage: newValue, url: viewModel.secondLink))
            }
            .onChange(of: viewModel.secondLink) { oldValue, newValue in
                urlUpdate(viewModel.idTwo, newValue)
            }
            HStack {
                Text("Link")
                    .font(.system(size: 14, weight: .regular))
                    .padding(.trailing, 20.0)
                RoundedTextField(placeholder: "", text: $viewModel.thirdLink)
                IconPickerView(viewModel: .init(
                    selectedImage: viewModel.selectedIconThree ?? viewModel.savedIconThree,
                    shouldAutofetchImage: viewModel.selectedIconThree == nil,
                    searchText: viewModel.thirdLink,
                    completion: { image in
                        viewModel.savedIconThree = image
                        action(.init(id: viewModel.idThree, nsImage: image, url: viewModel.thirdLink))
                    }), userSelectedIcon: $viewModel.selectedIconThree, imageSize: .init(width: 50.0, height: 50.0)
                )
            }
            .frame(maxWidth: .infinity)
            .onChange(of: viewModel.selectedIconThree) { oldValue, newValue in
                action(.init(id: viewModel.idThree, nsImage: newValue, url: viewModel.thirdLink))
            }
            .onChange(of: viewModel.thirdLink) { oldValue, newValue in
                urlUpdate(viewModel.idThree, newValue)
            }
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Multiaction for websites")
                            .font(.system(size: 14, weight: .regular))
                        Toggle("", isOn: $viewModel.createMultiactions)
                            .toggleStyle(.switch)
                            .onChange(of: viewModel.createMultiactions) { oldValue, newValue in
                                createMultiactions(newValue)
                            }
                    }
                    .padding(.bottom, 6.0)
                    Text("This will create single button which will open all websites at once!")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.gray)
                }
                Spacer()
                VStack(alignment: .leading) {
                    Text("Select your favorite browser:")
                        .font(.headline)
                    
                    Picker("Select: ", selection: $viewModel.selectedBrowser) {
                        ForEach(Browsers.allCases) { browser in
                            Text(browser.rawValue).tag(browser)
                        }
                    }
                    .onChange(of: viewModel.selectedBrowser) { oldValue, newValue in
                        browser(newValue)
                    }
                }
                .frame(width: 300)
            }
        }
        .padding()
    }
}
