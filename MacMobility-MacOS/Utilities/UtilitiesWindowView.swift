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
    @State var uiControlCreateWindow: NSWindow?
    @State var uiControlCreateTestWindow: NSWindow?
    @StateObject var viewModel: ShortcutsViewModel
    @State private var appNameToFlash: String = ""
    
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
                ScrollViewReader { proxy in
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
                                                        .id(item.title)
                                                } else {
                                                    EmptyView()
                                                }
                                            } else {
                                                itemView(item: item)
                                                    .id(item.title)
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
                                            .id(item.title)
                                    } else {
                                        EmptyView()
                                    }
                                } else {
                                    itemView(item: item)
                                        .id(item.title)
                                }
                            }
                        }
                    }
                    .onChange(of: viewModel.scrollToApp) { _, title in
                        withAnimation {
                            proxy.scrollTo(title, anchor: .center)
                        } completion: {
                            appNameToFlash = title
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                appNameToFlash = ""
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
                    viewModel.draggingData = .init(size: item.size, indexes: item.indexes)
                    return NSItemProvider(object: item.id as NSString)
                } preview: {
                    RoundedRectangle(cornerRadius: 5.0)
                        .fill(Color.blue)
                        .frame(
                            width: 20 * (item.size?.width ?? 1) + 7.0 * (item.size?.width ?? 1),
                            height: 20 * (item.size?.height ?? 1) + 7.0 * (item.size?.height ?? 1)
                        )
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
            .background(item.title == appNameToFlash ? Color.yellow.opacity(0.5) : Color.clear)
            .animation(.easeOut, value: appNameToFlash)
            .padding(.horizontal, 16.0)
            .padding(.vertical, 6.0)
            Divider()
        }
    }
    
    private func openCreateNewUtilityWindow(item: ShortcutObject? = nil) {
        newWindow?.close()
        newWindow = nil
        if nil == newWindow {
            newWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 1150, height: 500),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            newWindow?.center()
            newWindow?.setFrameAutosaveName("NewUtility")
            newWindow?.isReleasedWhenClosed = false
            newWindow?.titlebarAppearsTransparent = true
            newWindow?.appearance = NSAppearance(named: .darkAqua)
            newWindow?.styleMask.insert(.fullSizeContentView)
            
            guard let visualEffect = NSVisualEffectView.createVisualAppearance(for: newWindow) else {
                return
            }
            
            newWindow?.contentView?.addSubview(visualEffect, positioned: .below, relativeTo: nil)
            let hv = NSHostingController(rootView: SelectUtilityTypeWindowView(
                connectionManager: viewModel.connectionManager,
                categories: viewModel.allCategories(),
                delegate: viewModel,
                closeAction: {
                    newWindow?.close()
                }))
            newWindow?.contentView?.addSubview(hv.view)
            hv.view.frame = newWindow?.contentView?.bounds ?? .zero
            hv.view.autoresizingMask = [.width, .height]
        }
        newWindow?.makeKeyAndOrderFront(nil)
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
            editUtilitiesWindow?.appearance = NSAppearance(named: .darkAqua)
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
                } else if item.type == .control {
                    if let type = UIControlType.typeFromPath(item.path) {
                        openCreateUIControlWindow(type: type, item: item)
                    }
                    return
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
                if item.type == .control {
                    if let type = UIControlType.typeFromPath(item.path) {
                        openCreateUIControlWindow(type: type, item: item)
                    }
                    return
                } else {
                    let hv = NSHostingController(rootView: NewAutomationUtilityView(categories: viewModel.allCategories(), showsSizePicker: true, item: item, delegate: viewModel) {
                        editUtilitiesWindow?.close()
                    })
                    editUtilitiesWindow?.contentView?.addSubview(hv.view)
                    hv.view.frame = editUtilitiesWindow?.contentView?.bounds ?? .zero
                    hv.view.autoresizingMask = [.width, .height]
                }
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
    
    func openCreateUIControlWindow(type: UIControlType, item: ShortcutObject) {
        uiControlCreateWindow?.close()
        uiControlCreateWindow = nil
        if nil == uiControlCreateWindow {
            uiControlCreateWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 850, height: 700),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            uiControlCreateWindow?.center()
            uiControlCreateWindow?.setFrameAutosaveName("UIControlCreateWindow")
            uiControlCreateWindow?.isReleasedWhenClosed = false
            uiControlCreateWindow?.titlebarAppearsTransparent = true
            uiControlCreateWindow?.appearance = NSAppearance(named: .darkAqua)
            uiControlCreateWindow?.styleMask.insert(.fullSizeContentView)
            
            guard let visualEffect = NSVisualEffectView.createVisualAppearance(for: uiControlCreateWindow) else {
                return
            }
            
            uiControlCreateWindow?.contentView?.addSubview(visualEffect, positioned: .below, relativeTo: nil)
            let hv = NSHostingController(rootView: UIControlCreateView(
                type: type,
                connectionManager: viewModel.connectionManager,
                categories: viewModel.allCategories(),
                item: item,
                delegate: viewModel,
                closeAction: { object in
                    uiControlCreateWindow?.close()
                    guard let object else { return }
                    if let category = object.category {
                        viewModel.expandSectionIfNeeded(for: category)
                    }
                    viewModel.saveUtility(with: object)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        viewModel.scrollToApp = object.title
                    }
                }, testAction: { payload in
                    openCreateUIControlTestWindow(payload: payload)
                }
            ))
            uiControlCreateWindow?.contentView?.addSubview(hv.view)
            hv.view.frame = uiControlCreateWindow?.contentView?.bounds ?? .zero
            hv.view.autoresizingMask = [.width, .height]
        }
        uiControlCreateWindow?.makeKeyAndOrderFront(nil)
    }
    
    func openCreateUIControlTestWindow(payload: UIControlPayload) {
        uiControlCreateTestWindow?.close()
        uiControlCreateTestWindow = nil
        if nil == uiControlCreateTestWindow {
            uiControlCreateTestWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: payload.type.size.width * 120, height: payload.type.size.height * 120),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            uiControlCreateTestWindow?.center()
            uiControlCreateTestWindow?.setFrameAutosaveName("UIControlCreateTestWindow")
            uiControlCreateTestWindow?.isReleasedWhenClosed = false
            uiControlCreateTestWindow?.titlebarAppearsTransparent = true
            uiControlCreateTestWindow?.appearance = NSAppearance(named: .darkAqua)
            uiControlCreateTestWindow?.styleMask.insert(.fullSizeContentView)
            
            guard let visualEffect = NSVisualEffectView.createVisualAppearance(for: uiControlCreateTestWindow) else {
                return
            }
            
            uiControlCreateTestWindow?.contentView?.addSubview(visualEffect, positioned: .below, relativeTo: nil)
            let hv = NSHostingController(rootView: UIControlTestView(
                payload: payload,
                connectionManager: viewModel.connectionManager
            ))
            uiControlCreateTestWindow?.contentView?.addSubview(hv.view)
            hv.view.frame = uiControlCreateTestWindow?.contentView?.bounds ?? .zero
            hv.view.autoresizingMask = [.width, .height]
        }
        uiControlCreateTestWindow?.makeKeyAndOrderFront(nil)
    }
}
