//
//  WebpagesWindowView.swift
//  MacMobility-MacOS
//
//  Created by CoderBlocks on 14/03/2024.
//

import SwiftUI

protocol WebpagesWindowDelegate: AnyObject {
    func saveWebpage(with webpageItem: ShortcutObject)
    var close: () -> Void { get }
}

struct WebpagesWindowView: View {
    @State private var newWindow: NSWindow?
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
                ScrollView {
                    ForEach(viewModel.webpages) { item in
                        if let scriptCode = item.scriptCode {
                            if scriptCode.isEmpty {
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
                    NSItemProvider(object: item.id as NSString)
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
            .padding(.horizontal, 16.0)
            .padding(.vertical, 6.0)
            Divider()
        }
    }
    
    private func openCreateNewWebpageWindow(item: ShortcutObject? = nil) {
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
            
            guard let visualEffect = NSVisualEffectView.createVisualAppearance(for: newWindow) else {
                return
            }
            newWindow?.contentView?.addSubview(visualEffect, positioned: .below, relativeTo: nil)
            let hv = NSHostingController(rootView: NewWebpageView(item: item, delegate: viewModel))
            viewModel.close = {
                newWindow?.close()
            }
            newWindow?.contentView?.addSubview(hv.view)
            hv.view.frame = newWindow?.contentView?.bounds ?? .zero
            hv.view.autoresizingMask = [.width, .height]
            newWindow?.makeKeyAndOrderFront(nil)
            return
        }
        let hv = NSHostingController(rootView: NewWebpageView(item: item, delegate: viewModel))
        viewModel.close = {
            newWindow?.close()
        }
        newWindow?.contentView?.subviews.forEach { $0.removeFromSuperview() }
        newWindow?.contentView?.addSubview(hv.view)
        hv.view.frame = newWindow?.contentView?.bounds ?? .zero
        hv.view.autoresizingMask = [.width, .height]
        newWindow?.makeKeyAndOrderFront(nil)
    }
}
