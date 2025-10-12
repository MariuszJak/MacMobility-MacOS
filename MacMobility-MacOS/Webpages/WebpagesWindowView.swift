//
//  WebpagesWindowView.swift
//  MacMobility-MacOS
//
//  Created by CoderBlocks on 14/03/2024.
//

import SwiftUI

protocol WebpagesWindowDelegate: AnyObject {
    func saveWebpage(with webpageItem: ShortcutObject)
    var close: (ShortcutObject?) -> Void { get }
}

struct WebpagesWindowView: View {
    @State private var newWindow: NSWindow?
    @State private var allBrowserwWindow: NSWindow?
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
            Divider()
            if viewModel.webpages.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack {
                            Text("No webpages found.")
                                .font(.system(size: 24, weight: .medium))
                                .padding(.bottom, 12.0)
                            Button {
                                openCreateNewWebpageWindow()
                            } label: {
                                Text("Add new one!")
                                    .font(.system(size: 16.0))
                            }
                        }
                        Spacer()
                    }
                    Spacer()
                }
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        ForEach(viewModel.webpages) { item in
                            if let scriptCode = item.scriptCode {
                                if scriptCode.isEmpty {
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
                    .onChange(of: viewModel.scrollToApp) { _, title in
                        guard title != "--> none" else { return }
                        withAnimation {
                            proxy.scrollTo(title, anchor: .center)
                        } completion: {
                            appNameToFlash = title
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                appNameToFlash = ""
                                viewModel.scrollToApp = "--> none"
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
                            .aspectRatio(contentMode: .fill)
                            .cornerRadius(Constants.cornerRadius)
                            .frame(width: Constants.imageSize, height: Constants.imageSize)
                            .clipShape(
                                RoundedRectangle(cornerRadius: Constants.cornerRadius)
                            )
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
                    Text(item.title.isEmpty ? item.path ?? "Untitled" : item.title)
                }
                .onDrag {
                    viewModel.draggingData = .init(size: item.size, indexes: item.indexes)
                    return NSItemProvider(object: item.id as NSString)
                }
                Spacer()
                Image(systemName: "gear")
                    .resizable()
                    .frame(width: 16, height: 16)
                    .onTapGesture {
                        openCreateNewWebpageWindow(item: item)
                    }
                
                Image(systemName: "trash")
                    .resizable()
                    .frame(width: 16, height: 16)
                    .onTapGesture {
                        viewModel.removeWebItem(id: item.id)
                    }
            }
            .background(item.title == appNameToFlash ? Color.yellow.opacity(0.5) : Color.clear)
            .animation(.easeOut, value: appNameToFlash)
            .padding(.horizontal, 16.0)
            .padding(.vertical, 6.0)
            Divider()
        }
    }
    
    private func openCreateNewWebpageWindow(item: ShortcutObject? = nil) {
        newWindow?.close()
        newWindow = nil
        if nil == newWindow {
            newWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 600, height: 550),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            newWindow?.center()
            newWindow?.setFrameAutosaveName("Webpages")
            newWindow?.isReleasedWhenClosed = false
            newWindow?.titlebarAppearsTransparent = true
            newWindow?.appearance = NSAppearance(named: .darkAqua)
            newWindow?.styleMask.insert(.fullSizeContentView)
            if let item {
                newWindow?.title = "Edit URL Link"
            } else {
                newWindow?.title = "Create URL Link"
            }
            newWindow?.titleVisibility = .hidden
            guard let visualEffect = NSVisualEffectView.createVisualAppearance(for: newWindow) else {
                return
            }
            newWindow?.contentView?.addSubview(visualEffect, positioned: .below, relativeTo: nil)
            let hv = NSHostingController(rootView: NewWebpageView(item: item, delegate: viewModel))
            viewModel.close = { _ in
                newWindow?.close()
            }
            newWindow?.contentView?.addSubview(hv.view)
            hv.view.frame = newWindow?.contentView?.bounds ?? .zero
            hv.view.autoresizingMask = [.width, .height]
            newWindow?.makeKeyAndOrderFront(nil)
            return
        }
    }
}
