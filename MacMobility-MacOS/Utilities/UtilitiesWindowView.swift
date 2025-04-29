//
//  UtilitiesWindowView.swift
//  MacMobility-MacOS
//
//  Created by CoderBlocks on 19/03/2025.
//

import SwiftUI

protocol UtilitiesWindowDelegate: AnyObject {
    func saveUtility(with utilityItem: ShortcutObject)
    func allObjects() -> [ShortcutObject]
    var close: () -> Void { get }
}

struct UtilitiesWindowView: View {
    @State private var newWindow: NSWindow?
    @State private var editUtilitiesWindow: NSWindow?
    @State private var allBrowserwWindow: NSWindow?
    @StateObject var viewModel: ShortcutsViewModel
    
    enum Constants {
        static let imageSize = 46.0
        static let cornerRadius = 6.0
    }
    
    init(viewModel: ShortcutsViewModel) {
        self._viewModel = .init(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack {
            if viewModel.utilities.isEmpty || viewModel.utilities.allSatisfy({ $0.path == "Hidden" }) {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack {
                            Text("No utilities found.")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundStyle(Color.white)
                                .padding(.bottom, 12.0)
                            Button {
                                openCreateNewUtilityWindow()
                            } label: {
                                Text("Add new one!")
                                    .foregroundStyle(Color.white)
                                    .font(.system(size: 16.0))
                            }
                        }
                        Spacer()
                    }
                    Spacer()
                }
            } else {
                if viewModel.searchText.isEmpty {
                    HStack {
                        Spacer()
                        Button(viewModel.allSectionsExpanded ? "Collapse All" : "Expand All") {
                            viewModel.toggleAllSections()
                        }
                    }
                    .padding([.trailing, .top], 16.0)
                }
                ScrollView {
                    Spacer()
                        .frame(height: 16.0)
                    if viewModel.searchText.isEmpty {
                        ForEach(viewModel.sections) { section in
                            Section {
                                if section.isExpanded {
                                    ForEach(section.items) { item in
                                        if let path = item.path {
                                            if path.isEmpty || path != "Hidden" {
                                                itemView(item: item)
                                            } else {
                                                EmptyView()
                                            }
                                        } else {
                                            itemView(item: item)
                                        }
                                    }
                                } else {
                                    EmptyView()
                                }
                            } header: {
                                HStack {
                                    Image(systemName: section.isExpanded ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                                        .padding(.leading, 16.0)
                                    Text(section.title)
                                        .font(.headline)
                                        .padding(.vertical, 12)
                                        .padding(.horizontal)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.gray.opacity(0.2))
                                .onTapGesture {
                                    viewModel.toggleCollapseForSection(for: section.title)
                                }
                            }
                        }
                    } else {
                        ForEach(viewModel.utilities) { item in
                            if let path = item.path {
                                if path.isEmpty || path != "Hidden" {
                                    itemView(item: item)
                                } else {
                                    EmptyView()
                                }
                            } else {
                                itemView(item: item)
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            for window in NSApplication.shared.windows {
                window.appearance = NSAppearance(named: .darkAqua)
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
    
    private func itemView(item: ShortcutObject) -> some View {
        VStack {
            HStack {
                HStack {
                    if let data = item.imageData, let image = NSImage(data: data) {
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(Constants.cornerRadius)
                            .frame(width: Constants.imageSize, height: Constants.imageSize)
                    } else if let link = item.faviconLink, let url = URL(string: link) {
                        AsyncImage(url: url,
                                   content: { image in
                            image
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(Constants.cornerRadius)
                                .frame(width: Constants.imageSize, height: Constants.imageSize)
                        }, placeholder: {
                            Image("Empty")
                                .resizable()
                                .cornerRadius(Constants.cornerRadius)
                                .frame(width: Constants.imageSize, height: Constants.imageSize)
                        })
                        .cornerRadius(Constants.cornerRadius)
                        .frame(width: Constants.imageSize, height: Constants.imageSize)
                    } else {
                        if let browser = item.browser {
                            Image(browser.icon)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(Constants.cornerRadius)
                                .frame(width: Constants.imageSize, height: Constants.imageSize)
                        }
                    }
                    Text(item.title)
                }
                .onDrag {
                    NSItemProvider(object: item.id as NSString)
                }
                Spacer()
                Image(systemName: "gear")
                    .resizable()
                    .frame(width: 16, height: 16)
                    .onTapGesture {
                        openEditUtilityWindow(item: item)
                    }
                
                Image(systemName: "trash")
                    .resizable()
                    .frame(width: 16, height: 16)
                    .onTapGesture {
                        viewModel.removeUtilityItem(id: item.id)
                    }
            }
            .padding(.horizontal, 16.0)
            .padding(.vertical, 6.0)
            Divider()
        }
    }
    
    private func openCreateNewUtilityWindow(item: ShortcutObject? = nil) {
        if nil == newWindow {
            newWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 800, height: 400),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            newWindow?.center()
            newWindow?.setFrameAutosaveName("NewUtility")
            newWindow?.isReleasedWhenClosed = false
            newWindow?.contentView = NSHostingView(rootView: SelectUtilityTypeWindowView(
                connectionManager: viewModel.connectionManager,
                categories: viewModel.allCategories(),
                delegate: viewModel,
                closeAction: {
                    newWindow?.close()
                }))
        }
        newWindow?.contentView = NSHostingView(rootView: SelectUtilityTypeWindowView(
            connectionManager: viewModel.connectionManager,
            categories: viewModel.allCategories(),
            delegate: viewModel,
            closeAction: {
                newWindow?.close()
            }))
        newWindow?.makeKeyAndOrderFront(nil)
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
