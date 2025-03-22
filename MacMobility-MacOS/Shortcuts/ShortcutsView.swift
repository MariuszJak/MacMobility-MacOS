//
//  ShortcutsView.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 16/03/2025.
//

import SwiftUI

struct ShortcutsView: View {
    @State private var newWindow: NSWindow?
    @State private var editUtilitiesWindow: NSWindow?
    @ObservedObject private var viewModel: ShortcutsViewModel
    @State private var selectedTab = 0
    let cornerRadius = 17.0
    
    init(viewModel: ShortcutsViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Editor")
                    .font(.system(size: 17.0, weight: .bold))
                    .padding([.horizontal, .top], 16)
            }
            Divider()
        }
        HStack {
            VStack(alignment: .leading) {
                HStack(alignment: .bottom) {
                    Image(systemName: "plus.circle.fill")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .padding([.horizontal, .top], 16.0)
                        .onTapGesture {
                            viewModel.addPage()
                        }
                    Text("Add page")
                }
                ScrollView {
                    ForEach(1..<viewModel.pages+1, id: \.self) { page in
                        HStack {
                            Text("Page: \(page)")
                                .font(.system(size: 16, weight: .bold))
                            Spacer()
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
                                                        viewModel.removeShortcut(id: id)
                                                    }
                                                }
                                                Spacer()
                                            }
                                        }
                                        
                                    }
                                }
                                .frame(width: 70, height: 70)
                                .background(
                                    RoundedRectangle(cornerRadius: cornerRadius)
                                        .fill(viewModel.objectAt(index: index, page: page)?.color.let { Color(hex: $0) } ?? Color.black.opacity(0.4))
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
                    }
                }
                .frame(minWidth: 600)
            }
            VStack {
                TextField("Search...", text: $viewModel.searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding([.horizontal, .bottom], 16.0)
                TabView(selection: $selectedTab) {
                    installedAppsView
                        .tabItem( { Text("Applications") })
                        .tag(0)
                    shortcutsView
                        .tabItem( { Text("Shortcuts") })
                        .tag(1)
                    websitesView
                        .tabItem( { Text("Websites") })
                        .tag(2)
                    utilitiesView
                        .tabItem( { Text("Utilities") })
                        .tag(3)
                }
                .tabViewStyle(.automatic)
                .padding([.horizontal, .bottom])
                .onChange(of: selectedTab) { _, _ in
                    viewModel.searchText = ""
                }
            }
        }
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
                        objects: object.objects
                    )
            )
        }
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
                Text(object.title)
                    .font(.system(size: 12))
                    .multilineTextAlignment(.center)
                    .padding(.all, 3)
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
                } else if let path = object.browser?.icon {
                    Image(path)
                        .resizable()
                        .frame(width: 80, height: 80)
                        .cornerRadius(cornerRadius)
                        .onTapGesture {
                            openCreateNewWebpageWindow(item: object)
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
                    Text(object.title)
                        .font(.system(size: 11))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(maxWidth: 80)
                        .background(
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.black.opacity(0.8))
                        )
                        .padding(.top, 20)
                        .onTapGesture {
                            openEditUtilityWindow(item: object)
                        }
                }
            }
        }
    }
    
    private var shortcutsView: some View {
        VStack(alignment: .leading) {
            ScrollView {
                ForEach(viewModel.shortcuts) { shortcut in
                    HStack {
                        RoundedRectangle(cornerRadius: cornerRadius / 2)
                            .fill(Color(hex: shortcut.color ?? ""))
                            .frame(width: 38, height: 38)
                            .padding(.trailing, 8)
                        Text(shortcut.title)
                            .padding(.vertical, 6.0)
                        Spacer()
                    }
                    .onDrag {
                        NSItemProvider(object: shortcut.id as NSString)
                    }
                    Divider()
                }
            }
        }
        .padding()
    }
    
    private var installedAppsView: some View {
        VStack(alignment: .leading) {
            ScrollView {
                ForEach(viewModel.installedApps) { app in
                    HStack {
                        HStack {
                            Image(nsImage: NSWorkspace.shared.icon(forFile: app.path ?? ""))
                                .resizable()
                                .frame(width: 38, height: 38)
                                .cornerRadius(cornerRadius)
                                .padding(.trailing, 8)
                            Text(app.title)
                                .padding(.vertical, 6.0)
                        }
                        Spacer()
                    }
                    .onDrag {
                        NSItemProvider(object: app.id as NSString)
                    }
                    Divider()
                }
            }
        }
        .padding()
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
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 200),
                styleMask: [.titled, .closable, .resizable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            newWindow?.center()
            newWindow?.setFrameAutosaveName("Webpages")
            newWindow?.isReleasedWhenClosed = false
            newWindow?.contentView = NSHostingView(rootView: NewWebpageView(item: item, delegate: viewModel))
            viewModel.close = {
                newWindow?.close()
            }
        }
        newWindow?.contentView = NSHostingView(rootView: NewWebpageView(item: item, delegate: viewModel))
        newWindow?.makeKeyAndOrderFront(nil)
    }
    
    private func openEditUtilityWindow(item: ShortcutObject) {
        if nil == editUtilitiesWindow {
            editUtilitiesWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 320, height: 500),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            editUtilitiesWindow?.center()
            editUtilitiesWindow?.setFrameAutosaveName("Utilities")
            editUtilitiesWindow?.isReleasedWhenClosed = false
            switch item.utilityType {
            case .commandline:
                editUtilitiesWindow?.contentView = NSHostingView(rootView: NewBashUtilityView(item: item, delegate: viewModel) {
                    editUtilitiesWindow?.close()
                })
            case .multiselection:
                editUtilitiesWindow?.contentView = NSHostingView(rootView: NewMultiSelectionUtilityView(item: item, delegate: viewModel) {
                    editUtilitiesWindow?.close()
                })
            case .none:
                break
            }
            
        }
        switch item.utilityType {
        case .commandline:
            editUtilitiesWindow?.contentView = NSHostingView(rootView: NewBashUtilityView(item: item, delegate: viewModel){
                editUtilitiesWindow?.close()
            })
        case .multiselection:
            editUtilitiesWindow?.contentView = NSHostingView(rootView: NewMultiSelectionUtilityView(item: item, delegate: viewModel) {
                editUtilitiesWindow?.close()
            })
        case .none:
            break
        }
        editUtilitiesWindow?.makeKeyAndOrderFront(nil)
    }
}
