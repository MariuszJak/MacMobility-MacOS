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
    let closeAction: () -> Void
    
    init(closeAction: @escaping () -> Void) {
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
        closeAction()
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
                    AppSetupChoiceView()
                case 4:
                    AutodetectAutomationInstallView()
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

struct SetupMode: Identifiable {
    let id: UUID = UUID()
    let title: String
    let description: String
    let imageName: String
}

struct AppSetupChoiceView: View {
    @State private var selectedMode: String = "prepared"
    
    let options: [SetupMode] = [
        SetupMode(title: "Start with Basic Actions",
                  description: "Get started quickly with a few handy automations and shortcuts already set up for you.",
                  imageName: "sparkles"),
        
        SetupMode(title: "Start Blank",
                  description: "Build your workspace from scratch with no predefined actions or shortcuts.",
                  imageName: "square.dashed")
    ]
    
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
    let imageName: String
    var isSelected: Bool = true
}

struct AutodetectAutomationInstallView: View {
    @State private var options: [AutomationOption] = [
        AutomationOption(title: "macOS System",
                         description: "Essential system-level automations to help you work faster on your Mac.",
                         imageName: "gearshape"),
        
        AutomationOption(title: "Xcode",
                         description: "Useful automations for running builds, cleaning, and opening projects quickly.",
                         imageName: "hammer"),
        
        AutomationOption(title: "Safari",
                         description: "Quick actions for opening bookmarks, private windows, and clearing tabs.",
                         imageName: "safari"),
        
        AutomationOption(title: "Safari",
                         description: "Quick actions for opening bookmarks, private windows, and clearing tabs.",
                         imageName: "safari")
    ]
    
    @State private var allSelected: Bool = true

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
                            for index in options.indices {
                                options[index].isSelected = newValue
                            }
                        }
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .help(allSelected ? "Turn off all automations" : "Turn on all automations")
                }
                .padding(.trailing, 16.0)
                ScrollView {
                    ForEach($options) { $option in
                        HStack(spacing: 16) {
                            Image(systemName: option.imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(option.title)
                                    .font(.headline)
                                
                                Text(option.description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $option.isSelected)
                                .toggleStyle(.switch)
                                .labelsHidden()
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
        .onAppear {
            allSelected = options.allSatisfy { $0.isSelected }
        }
    }
    
    private func updateMasterToggleState() {
        allSelected = options.allSatisfy { $0.isSelected }
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
