//
//  WebpagesWindowView.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 14/03/2024.
//

import SwiftUI

protocol WebpagesWindowDelegate: AnyObject {
    func saveWebpage(with webpageItem: WebpageItem)
    var close: () -> Void { get }
}

struct WebpagesWindowView: View {
    @State private var newWindow: NSWindow?
    @State private var allBrowserwWindow: NSWindow?
    @StateObject var viewModel = WebpagesWindowViewModel()
    let connectionManager: ConnectionManager
    
    init(connectionManager: ConnectionManager) {
        self.connectionManager = connectionManager
    }
    
    var body: some View {
        VStack {
            List {
                Text("Webpages links")
                ForEach(viewModel.webpages) { item in
                    HStack {
                        Text(item.webpageTitle)
                        Spacer()
                        Button(action: {
                            openCreateNewWebpageWindow(item: item)
                        }, label: {
                            Text("Edit")
                        })
                        Button(action: {
                            viewModel.removeWebPageItem(with: item)
                        }, label: {
                            Text("Delete")
                        })
                    }
                }.onMove(perform: { from, to in
                    viewModel.webpages.move(fromOffsets: from, toOffset: to)
                    viewModel.saveWebpages()
                })
                Spacer()
                Button(action: {
                    openCreateNewWebpageWindow()
                }, label: {
                    Image("plus")
                })
                Button {
                    openAllWebpageWindow()
                } label: {
                    Text("Open all webpages")
                }
            }
        }
        .frame(minWidth: 400, minHeight: 200)
        .padding()
        .onChange(of: viewModel.webpages) { webpages, _ in
            connectionManager.webpages = webpages
        }
    }
    
    private func openCreateNewWebpageWindow(item: WebpageItem? = nil) {
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
            newWindow?.contentView = NSHostingView(rootView: NewWebpageView(item: item, delegate: viewModel))
            viewModel.close = {
                newWindow?.close()
            }
        }
        newWindow?.contentView = NSHostingView(rootView: NewWebpageView(item: item, delegate: viewModel))
        newWindow?.makeKeyAndOrderFront(nil)
    }
    
    private func openAllWebpageWindow() {
        if nil == allBrowserwWindow {
            allBrowserwWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 200),
                styleMask: [.closable, .titled, .resizable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            allBrowserwWindow?.center()
            allBrowserwWindow?.setFrameAutosaveName("AllWebpages")
            allBrowserwWindow?.isReleasedWhenClosed = false
            allBrowserwWindow?.titlebarAppearsTransparent = true
            allBrowserwWindow?.styleMask.insert(.fullSizeContentView)
            allBrowserwWindow?.contentView = NSHostingView(rootView: AllWebpagesView(viewModel: viewModel))
            viewModel.close = {
                newWindow?.close()
            }
        }
        allBrowserwWindow?.makeKeyAndOrderFront(nil)
    }
}

class WebpagesWindowViewModel: ObservableObject, WebpagesWindowDelegate {
    @Published var selectedId: String?
    @Published var webpages: [WebpageItem] = []
    var close: () -> Void = {}
    
    init(selectedId: String? = nil, close: @escaping () -> Void = {}) {
        self.selectedId = selectedId
        self.webpages = UserDefaults.standard.getWebItems() ?? []
        self.close = close
    }
    
    func refreshFromStorage() {
        webpages = UserDefaults.standard.getWebItems() ?? []
    }
    
    func getAutomations() -> [WebpageItem] {
        webpages
    }
    
    func saveWebpage(with webpageItem: WebpageItem) {
        if let index = webpages.firstIndex(where: { $0.id == webpageItem.id }) {
            webpages[index] = webpageItem
            UserDefaults.standard.storeWebItems(webpages)
            return
        }
        webpages.append(webpageItem)
        UserDefaults.standard.storeWebItems(webpages)
    }
    
    func removeWebPageItem(with webpageItem: WebpageItem) {
        webpages = webpages.filter { $0.id != webpageItem.id }
        UserDefaults.standard.storeWebItems(webpages)
    }
    
    func saveWebpages() {
        UserDefaults.standard.storeWebItems(webpages)
    }
}

struct WebpageItem: Identifiable, Codable, Equatable {
    var id: String
    var webpageTitle: String
    var webpageLink: String
    var faviconLink: String?
    var browser: Browsers
}
