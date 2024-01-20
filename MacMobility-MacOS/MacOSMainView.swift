//
//  ContentView.swift
//  MagicTrackpad
//
//  Created by Mariusz Jakowienko on 05/07/2023.
//

import SwiftUI
import QRCode
import os

enum WorkspaceControl: String, CaseIterable {
    case prev, next
}

struct MacOSMainPopoverView: View {
    @StateObject var connectionManager = ConnectionManager()
    @State private var newWindow: NSWindow?
    @State var isAccessibilityGranted: Bool = false
    private var spacing = 6.0
    
    init() {
        self.isAccessibilityGranted = AXIsProcessTrusted()
    }
    
    var body: some View {
        VStack(spacing: .zero) {
            VStack(alignment: .leading, spacing: spacing) {
                HStack(alignment: .top, spacing: spacing * 2) {
                    VStack(alignment: .leading, spacing: spacing) {
                        permissionView
                        //testWindowButtonView
                        pairiningView
                        if connectionManager.isConnecting {
                            Spacer()
                        }
                        Divider()
                        quitView
                    }
                    if connectionManager.isConnecting {
                        Divider()
                    }
                    qrCodeView
                }
            }
            .buttonStyle(PlainButtonStyle())
            .frame(width: connectionManager.isConnecting ? 270 : 200)
            .if(connectionManager.isConnecting) {
                $0.frame(maxHeight: 130)
            }
            .padding()
        }
    }
    
    private func openTestWindow() {
        if nil == newWindow {
            newWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 200),
                styleMask: [.titled, .closable, .resizable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            newWindow?.center()
            newWindow?.setFrameAutosaveName("Preferences")
            newWindow?.isReleasedWhenClosed = false
            newWindow?.contentView = NSHostingView(rootView: AutomationsWindowView(connectionManager: connectionManager))
        }
        newWindow?.makeKeyAndOrderFront(nil)
    }
    
    private var qrCodeView: some View {
        VStack(spacing: .zero) {
            if connectionManager.isConnecting {
                VStack(spacing: spacing) {
                    if let image = generateQRCode() {
                        Text("Scan to connect")
                        Image(nsImage: image)
                            .resizable()
                            .frame(width: 80, height: 80)
                    }
                }
            } else {
                VStack {}
            }
        }
    }
    
    private var permissionView: some View {
        Button("Ask for permission") {
            guard !AXIsProcessTrusted() else { return }
            let alert = NSAlert()
            alert.messageText = "Accessibility Access Required"
            alert.informativeText = "Your app needs accessibility access to perform certain actions. Please enable accessibility access in System Preferences."
            alert.addButton(withTitle: "Open System Preferences")
            alert.addButton(withTitle: "Cancel")
            
            let response = alert.runModal()
            if response == NSApplication.ModalResponse.alertFirstButtonReturn {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
            }
        }
        .disabled(AXIsProcessTrusted())
    }
    
    private var testWindowButtonView: some View {
        Button("Test window") {
            openTestWindow()
        }
    }
    
    @ViewBuilder
    private var pairiningView: some View {
        switch connectionManager.pairingStatus {
        case .notPaired:
            if let availablePeer = connectionManager.availablePeer {
                VStack(alignment: .leading, spacing: spacing) {
                    Button("Connect to \(availablePeer.displayName)") {
                        connectionManager.invitePeer(with: availablePeer)
                        connectionManager.pairingStatus = .pairining
                    }
                }
            }
        case .paired:
            VStack(alignment: .leading, spacing: spacing) {
                Button("Disconnect from \(connectionManager.connectedPeerName ?? "")") {
                    connectionManager.disconnect()
                    connectionManager.pairingStatus = .notPaired
                }
            }
        case .pairining:
            Text("Pairining...(please wait)")
                .foregroundStyle(.gray)
        }
    }
    
    private var quitView: some View {
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }.keyboardShortcut("q")
    }
    
    func generateQRCode() -> NSImage? {
        let code = connectionManager.generateUUID()
        let doc = QRCode.Document(utf8String: code, errorCorrection: .high)
        guard let generated = doc.cgImage(CGSize(width: 800, height: 800)) else { return nil }
        return NSImage(cgImage: generated, size: .init(width: 80, height: 80))
    }
}


extension View {
    @ViewBuilder
    func `if`<Content: View>(_ conditional: Bool, content: (Self) -> Content) -> some View {
        if conditional {
            content(self)
        } else {
            self
        }
    }
}

struct AutomationsWindowView: View {
    @State private var newWindow: NSWindow?
    @StateObject var viewModel = AutomationsWindowViewModel()
    let connectionManager: ConnectionManager
    
    init(connectionManager: ConnectionManager) {
        self.connectionManager = connectionManager
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(connectionManager.getRunningApps()) { app in
                    NavigationLink(app.id, tag: app.id, selection: $viewModel.selectedId) {
                        linkPage(for: app.title)
                    }
                }
            }
            .listStyle(.sidebar)
            Text("No selection")
        }
    }
    
    @ViewBuilder
    private func linkPage(for application: String) -> some View {
        let automations = viewModel.getAutomations(for: application)
        if automations.isEmpty {
            Text("No automations. Press '+' to add new one.")
                .navigationTitle(application)
            Button {
                openCreateNewAutomationWindow(for: application)
            } label: {
                Image("plus")
            }
        } else {
            List(automations) { automation in
                Text(automation.title)
            }
            HStack {
                Button {
                    openCreateNewAutomationWindow(for: application)
                } label: {
                    Image("plus")
                }
                Spacer()
            }
            .padding()
        }
    }
    
    private func openCreateNewAutomationWindow(for application: String) {
        if nil == newWindow {
            newWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 200),
                styleMask: [.titled, .closable, .resizable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            newWindow?.center()
            newWindow?.setFrameAutosaveName("Preferences")
            newWindow?.isReleasedWhenClosed = false
            newWindow?.contentView = NSHostingView(rootView: NewAutomationView(parentApp: application,
                                                                               delegate: viewModel))
            viewModel.close = {
                newWindow?.close()
            }
        }
        newWindow?.makeKeyAndOrderFront(nil)
    }
}

protocol AutomationsWindowDelegate: AnyObject {
    func saveAutomation(with automationItem: AutomationItem)
    var close: () -> Void { get }
}

struct NewAutomationView: View {
    @ObservedObject var viewModel = NewAutomationViewModel()
    let parentApp: String
    weak var delegate: AutomationsWindowDelegate?
    
    init(parentApp: String, delegate: AutomationsWindowDelegate?) {
        self.parentApp = parentApp
        self.delegate = delegate
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Automation title:")
            TextField("", text: $viewModel.title)
            Text("Automation:")
            TextEditor(text: $viewModel.automationText)
                .frame(height: 200.0)
            Button {
                delegate?.saveAutomation(with: .init(parentApp: parentApp,
                                                     title: viewModel.title,
                                                     automationText: viewModel.automationText))
                viewModel.clear()
                delegate?.close()
                
            } label: {
                Text("Save")
            }
        }
        .padding()
    }
}


struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value = value + nextValue()
    }
}

class NewAutomationViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var automationText: String = ""
    
    func clear() {
        title = ""
        automationText = ""
    }
}

class AutomationsWindowViewModel: ObservableObject, AutomationsWindowDelegate {
    @Published var selectedId: String?
    @Published var automations: [AutomationItem] = []
    var close: () -> Void = {}
    
    func getAutomations(for application: String) -> [AutomationItem] {
        self.automations.filter { $0.parentApp == application }
    }
    
    func saveAutomation(with automationItem: AutomationItem) {
        automations.append(automationItem)
    }
}

struct AutomationItem: Identifiable {
    var id: String { UUID().uuidString }
    var parentApp: String
    var title: String
    var automationText: String
}
