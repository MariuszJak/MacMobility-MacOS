//
//  SelectUtilityTypeWindowView.swift
//  MacMobility-MacOS
//
//  Created by CoderBlocks on 19/03/2025.
//

import SwiftUI

public struct UtilityObject: Identifiable {
    public let id: String = UUID().uuidString
    public enum UtilityType: String, Codable {
        case commandline
        case multiselection
        case automation
        case macro
        case html
    }
    let type: UtilityType
    let title: String
    let description: String
    
    public init(type: UtilityType, title: String, description: String) {
        self.type = type
        self.title = title
        self.description = description
    }
}

class SelectUtilityTypeWindowViewModel: ObservableObject {
    let connectionManager: ConnectionManager
    weak var delegate: UtilitiesWindowDelegate?
    
    @Published var utilities: [UtilityObject] = [
        .init(type: .commandline, title: "Commandline tool", description: "This tool allows creation of shortcuts for triggering Bash scripts remotely from companion device."),
        .init(type: .multiselection, title: "Multiselection tool", description: "This tool allows creation of multiactions that can be triggered remotely from companion device."),
        .init(type: .automation, title: "Automation tool", description: "This tool allows creation of workflows that can be triggered remotely from companion device."),
        .init(type: .macro, title: "Macros", description: "This tool allows creation of macros that can be triggered remotely from companion device."),
        .init(type: .commandline, title: "File Converter", description: "This tool allows conversion of files between different formats. You can define a file format input and output."),
        .init(type: .commandline, title: "Raycast", description: "This tool allows triggering Raycast commands remotely from companion device using deeplinks."),
        .init(type: .html, title: "HTML", description: "This tool allows creating small html based widgets that refresh periodically.")
    ]
    
    init(connectionManager: ConnectionManager, delegate: UtilitiesWindowDelegate?) {
        self.connectionManager = connectionManager
        self.delegate = delegate
    }
}

struct SelectUtilityTypeWindowView: View {
    @StateObject var viewModel: SelectUtilityTypeWindowViewModel
    @State var newWindow: NSWindow?
    let connectionManager: ConnectionManager
    let categories: [String]
    let closeAction: () -> Void
    
    init(connectionManager: ConnectionManager, categories: [String], delegate: UtilitiesWindowDelegate?, closeAction: @escaping () -> Void) {
        self.connectionManager = connectionManager
        self.closeAction = closeAction
        self.categories = categories
        self._viewModel = .init(wrappedValue: .init(connectionManager: connectionManager, delegate: delegate))
    }
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Select utility type")
                            .font(.system(size: 17.0, weight: .bold))
                            .foregroundStyle(Color.white)
                            .padding([.horizontal, .top], 16)
                        Spacer()
                    }
                    Divider()
                    if !viewModel.utilities.isEmpty {
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 240))], spacing: 6) {
                                ForEach(viewModel.utilities) { utility in
                                    VStack(alignment: .leading) {
                                        VStack(alignment: .leading) {
                                            Text(utility.title)
                                                .lineLimit(1)
                                                .font(.system(size: 16, weight: .bold))
                                                .padding(.bottom, 4)
                                            Text(utility.description)
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundStyle(Color.gray)
                                                .padding(.bottom, 8)
                                            Divider()
                                            HStack {
                                                Image(systemName: "plus.circle.fill")
                                                    .resizable()
                                                    .frame(width: 16, height: 16)
                                                    .onTapGesture {
                                                        closeAction()
                                                        openCreateNewUtilityWindow(type: utility.type, title: utility.title)
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
                                        .foregroundStyle(Color.white)
                                        .padding(.bottom, 12.0)
                                    Button {
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
                    }
                }
            }
            .background(
                RoundedBackgroundView()
            )
        }
        .onAppear {
            for window in NSApplication.shared.windows {
                window.appearance = NSAppearance(named: .darkAqua)
            }
        }
        .padding()
    }
    
    private func openCreateNewUtilityWindow(type: UtilityObject.UtilityType, title: String, item: ShortcutObject? = nil) {
        if nil == newWindow {
            if title == "File Converter" {
                newWindow = NSWindow(
                    contentRect: NSRect(x: 0, y: 0, width: 520, height: 300),
                    styleMask: [.titled, .closable, .miniaturizable],
                    backing: .buffered,
                    defer: false
                )
                newWindow?.center()
                newWindow?.setFrameAutosaveName("CreateNewUtility")
                newWindow?.isReleasedWhenClosed = false
                newWindow?.titlebarAppearsTransparent = true
                newWindow?.styleMask.insert(.fullSizeContentView)
            } else {
                newWindow = NSWindow(
                    contentRect: NSRect(x: 0, y: 0, width: 520, height: type == .commandline ? 800 : 470),
                    styleMask: type == .commandline || type == .automation || type == .html ? [.titled, .closable, .resizable, .miniaturizable] : [.titled, .closable, .miniaturizable],
                    backing: .buffered,
                    defer: false
                )
                newWindow?.center()
                newWindow?.setFrameAutosaveName("CreateNewUtility")
                newWindow?.isReleasedWhenClosed = false
                newWindow?.titlebarAppearsTransparent = true
                newWindow?.styleMask.insert(.fullSizeContentView)
            }
            
            guard let visualEffect = NSVisualEffectView.createVisualAppearance(for: newWindow) else {
                return
            }
            
            newWindow?.contentView?.addSubview(visualEffect, positioned: .below, relativeTo: nil)
            
            switch type {
            case .commandline:
                if title == "File Converter" {
                    let hv = NSHostingController(rootView: ConverterView(item: item, delegate: viewModel.delegate){
                        newWindow?.close()
                    })
                    newWindow?.contentView?.addSubview(hv.view)
                    hv.view.frame = newWindow?.contentView?.bounds ?? .zero
                    hv.view.autoresizingMask = [.width, .height]
                } else if title == "Raycast" {
                    let hv = NSHostingController(rootView: RaycastUtilityView(item: item, delegate: viewModel.delegate){
                        newWindow?.close()
                    })
                    newWindow?.contentView?.addSubview(hv.view)
                    hv.view.frame = newWindow?.contentView?.bounds ?? .zero
                    hv.view.autoresizingMask = [.width, .height]
                } else {
                    let hv = NSHostingController(rootView: NewBashUtilityView(categories: categories, item: item, delegate: viewModel.delegate) {
                        newWindow?.close()
                    })
                    newWindow?.contentView?.addSubview(hv.view)
                    hv.view.frame = newWindow?.contentView?.bounds ?? .zero
                    hv.view.autoresizingMask = [.width, .height]
                }
            case .html:
                let hv = NSHostingController(rootView: HTMLUtilityView(categories: categories, item: item, delegate: viewModel.delegate) {
                    newWindow?.close()
                })
                newWindow?.contentView?.addSubview(hv.view)
                hv.view.frame = newWindow?.contentView?.bounds ?? .zero
                hv.view.autoresizingMask = [.width, .height]
            case .multiselection:
                let hv = NSHostingController(rootView: NewMultiSelectionUtilityView(item: item, delegate: viewModel.delegate) {
                    newWindow?.close()
                })
                newWindow?.contentView?.addSubview(hv.view)
                hv.view.frame = newWindow?.contentView?.bounds ?? .zero
                hv.view.autoresizingMask = [.width, .height]
            case .automation:
                let hv = NSHostingController(rootView: NewAutomationUtilityView(categories: categories, item: item, delegate: viewModel.delegate) {
                    newWindow?.close()
                })
                
                newWindow?.contentView?.addSubview(hv.view)
                hv.view.frame = newWindow?.contentView?.bounds ?? .zero
                hv.view.autoresizingMask = [.width, .height]
            case .macro:
                let hv = NSHostingController(rootView: MacroRecorderView(item: item, delegate: viewModel.delegate){
                    newWindow?.close()
                })
                newWindow?.contentView?.addSubview(hv.view)
                hv.view.frame = newWindow?.contentView?.bounds ?? .zero
                hv.view.autoresizingMask = [.width, .height]
            }
            newWindow?.makeKeyAndOrderFront(nil)
            return
        }
        
    }
}
