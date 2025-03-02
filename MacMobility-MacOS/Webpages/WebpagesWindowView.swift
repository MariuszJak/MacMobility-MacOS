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
    
    enum Constants {
        static let imageSize = 46.0
        static let cornerRadius = 6.0
    }
    
    init(connectionManager: ConnectionManager) {
        self.connectionManager = connectionManager
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Webpages links")
                    .font(.system(size: 16.0, weight: .bold))
                    .padding([.horizontal, .top], 16)
                Spacer()
                Image(systemName: "arrow.up.right.square")
                    .resizable()
                    .frame(width: 16, height: 16)
                    .onTapGesture {
                        openAllWebpageWindow()
                    }
                    .padding(.top, 16.0)
                    .padding(.trailing, 4.0)
                Image(systemName: "plus.circle.fill")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .onTapGesture {
                        openCreateNewWebpageWindow()
                    }
                    .padding([.trailing, .top], 16.0)
            }
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
                List {
                    ForEach(viewModel.webpages) { item in
                        HStack {
                            if let link = item.faviconLink, let url = URL(string: link) {
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
                            }
                            Text(item.webpageTitle)
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
                                    viewModel.removeWebPageItem(with: item)
                                }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20.0)
                                .fill(Color.black.opacity(0.4))
                        )
                    }.onMove(perform: { from, to in
                        viewModel.webpages.move(fromOffsets: from, toOffset: to)
                        viewModel.saveWebpages()
                    })
                }
                .listStyle(.sidebar)
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
    
    public func toggleWebpagesWindow() {
        guard let allBrowserwWindow else { return }
        if allBrowserwWindow.isVisible {
            allBrowserwWindow.orderOut(nil)
        } else {
            openAllWebpageWindow()
        }
    }
    
    private func openAllWebpageWindow() {
        if nil == allBrowserwWindow {
            allBrowserwWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 200),
                styleMask: [.closable, .titled, .resizable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            allBrowserwWindow?.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
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
