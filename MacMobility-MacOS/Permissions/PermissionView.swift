//
//  PermissionView.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 28/03/2025.
//

import SwiftUI
import Network


public class PermissionViewModel: ObservableObject {
    @Published var isPermissionGranted: Bool? = nil
    private var browser: NWBrowser?
    
    public init() {
        checkLocalNetworkPermission()
    }
    
    func askForPermission() {
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
    
    func requestLocalNetworkAccess() {
        let parameters = NWParameters()
        parameters.includePeerToPeer = true // Enables peer-to-peer discovery
        
        // Looking for services on a local network (e.g., _http._tcp.)
        let browser = NWBrowser(for: .bonjour(type: "_http._tcp", domain: nil), using: parameters)
        self.browser = browser // Store reference to keep it alive
        
        browser.stateUpdateHandler = { newState in
            switch newState {
            case .failed(let error):
                print("Browser failed: \(error)")
            case .ready:
                print("Browser ready")
            default:
                break
            }
        }
        
        browser.browseResultsChangedHandler = { results, changes in
            print("Found services: \(results)")
        }
        
        browser.start(queue: DispatchQueue.global())
    }
    
    func checkLocalNetworkPermission() {
        let parameters = NWParameters()
        parameters.includePeerToPeer = true
        
        let testBrowser = NWBrowser(for: .bonjour(type: "_http._tcp", domain: nil), using: parameters)
        testBrowser.stateUpdateHandler = { newState in
            DispatchQueue.main.async {
                switch newState {
                case .failed(let error):
                    print("Browser failed: \(error)")
                    self.isPermissionGranted = false // Permission likely denied
                case .ready:
                    print("Browser ready")
                    self.isPermissionGranted = true // Permission granted
                default:
                    break
                }
            }
        }
        
        testBrowser.start(queue: DispatchQueue.global())
        
        // Store reference to prevent it from being deallocated
        self.browser = testBrowser
    }
}

public struct PermissionView: View {
    @ObservedObject private var viewModel = PermissionViewModel()
    
    public var body: some View {
        HStack {
            VStack {
                Spacer()
                Image(.logo)
                    .resizable()
                    .frame(width: 128, height: 128)
                    .cornerRadius(20)
                Spacer()
            }
            .padding()
            VStack(alignment: .leading) {
                Spacer()
                Text("Accessibility Permission")
                    .font(.system(size: 18, weight: .bold))
                    .padding(.bottom, 6.0)
                Text("We need access to your system to allow accessibility features to work correctly. Please allow this permission in your system preferences.")
                    .foregroundStyle(Color.gray)
                    .padding(.bottom, 18.0)
                Button("Ask for permission") {
                    viewModel.askForPermission()
                }
                .disabled(AXIsProcessTrusted())
                .padding(.bottom, 42)
                
                Text("Local Network Permission")
                    .font(.system(size: 18, weight: .bold))
                    .padding(.bottom, 6.0)
                Text("We need access to your local network to allow accessibility features to work correctly. Please allow this permission in your system preferences.")
                    .foregroundStyle(Color.gray)
                    .padding(.bottom, 18.0)
                Button("Ask for permission") {
                    viewModel.requestLocalNetworkAccess()
                }
                .disabled(viewModel.isPermissionGranted == true)
                Spacer()
            }
            .padding()
        }
        .padding(.horizontal, 21.0)
    }
}
