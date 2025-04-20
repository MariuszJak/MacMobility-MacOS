//
//  WelcomeView.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 19/04/2025.
//

import SwiftUI
import QRCode

class WelcomeViewModel: ObservableObject {
    @Published var currentPage = 0
    let pageLimit = 5
    let closeAction: (SetupMode?, [AutomationOption]?) -> Void
    private(set) var setupMode: SetupMode?
    private(set) var automationOptions: [AutomationOption]?
    
    init(closeAction: @escaping (SetupMode?, [AutomationOption]?) -> Void) {
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
        closeAction(setupMode, automationOptions)
    }
    
    func updateSetupMode(_ setupMode: SetupMode) {
        self.setupMode = setupMode
    }
    
    func updateAutomationOptions(_ automationOptions: [AutomationOption]) {
        self.automationOptions = automationOptions
    }
}

struct WelcomeView: View {
    @ObservedObject private var viewModel: WelcomeViewModel
    @State private var showWelcomeText = false
    @State private var scaleEffect: CGFloat = 0.8
    
    init(viewModel: WelcomeViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack {
            Group {
                switch viewModel.currentPage {
                case 0:
                    firstPage
                case 1:
                    secondPage
                case 2:
                    thirdPage
                case 3:
                    AppSetupChoiceView(viewModel.setupMode) { setupMode in
                        viewModel.updateSetupMode(setupMode)
                    }
                case 4:
                    AutodetectAutomationInstallView(viewModel: .init(viewModel.automationOptions) { options in
                        viewModel.updateAutomationOptions(options)
                    })
                case 5:
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
                }
                .padding()
            }
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
    
    private var firstPage: some View {
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
    
    private var thirdPage: some View {
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

            Text("Or search for “MacMobility” on the App Store.")
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

struct SetupMode: Identifiable, Equatable {
    let id: UUID = UUID()
    let title: String
    let description: String
    let imageName: String
    
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
                  imageName: "sparkles"),
        
        SetupMode(title: "Start Basic",
                  description: "Start with some basic automations and scripts to get you up and running.",
                  imageName: "square.dashed")
    ]
    
    init(_ setupMode: SetupMode?, action: @escaping (SetupMode) -> Void) {
        if let setupMode {
            self.selectedMode = setupMode == options.first ? "prepared" : "blank"
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
    var isSelected: Bool = true
    var isOptional: Bool = true
}

class AutodetectAutomationInstallViewModel: ObservableObject, JSONLoadable {
    @Published var options: [AutomationOption] = [
        .init(title: "macOS System",
              description: "Essential system-level automations to help you work faster on your Mac.",
              imageName: "gearshape",
              imageData: nil,
              isOptional: false)
    ]
    
    var updateAction: ([AutomationOption]) -> Void
    
    init(_ options: [AutomationOption]?, updateAction: @escaping ([AutomationOption]) -> Void) {
        self.updateAction = updateAction
        if let options {
            self.options = options
        } else {
            fetchInstalledApps()
        }
    }
    
    func fetchInstalledApps() {
        let appDirectories = [
            "/Applications",
            "/System/Applications/Utilities"
        ]

        var apps: [String] = []

        for directory in appDirectories {
            apps.append(contentsOf: findApps(in: directory))
        }
        
        let automations: AutomationsList = loadJSON("automations")
        automations.automations.forEach { automation in
            if apps.contains(where: { $0 == automation.title }) {
                options.append(.init(title: automation.title, description: automation.description, imageName: nil, imageData: automation.imageData))
            }
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
                Button(action: {
                    closeAction()
                }) {
                    Text("Let's Start")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
                .buttonStyle(PlainButtonStyle())
                .transition(.opacity)
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
