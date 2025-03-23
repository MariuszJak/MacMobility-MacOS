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
            HStack {
                Text("Utilities")
                    .font(.system(size: 16.0, weight: .bold))
                    .padding([.horizontal, .top], 16)
                Spacer()
                Image(systemName: "plus.circle.fill")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .onTapGesture {
                        openCreateNewUtilityWindow()
                    }
                    .padding([.trailing, .top], 16.0)
            }
            Divider()
            if viewModel.utilities.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack {
                            Text("No utilities found.")
                                .font(.system(size: 24, weight: .medium))
                                .padding(.bottom, 12.0)
                            Button {
                                openCreateNewUtilityWindow()
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
                    ForEach(viewModel.utilities) { item in
                        if let path = item.path {
                            if path.isEmpty {
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
        .padding()
    }
    
    private func itemView(item: ShortcutObject) -> some View {
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
        .onDrag {
            NSItemProvider(object: item.id as NSString)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20.0)
                .fill(Color.black.opacity(0.4))
        )
    }
    
    private func openCreateNewUtilityWindow(item: ShortcutObject? = nil) {
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
            newWindow?.contentView = NSHostingView(rootView: SelectUtilityTypeWindowView(
                connectionManager: viewModel.connectionManager,
                delegate: viewModel,
                closeAction: {
                    newWindow?.close()
                }))
        }
        newWindow?.contentView = NSHostingView(rootView: SelectUtilityTypeWindowView(
            connectionManager: viewModel.connectionManager,
            delegate: viewModel,
            closeAction: {
                newWindow?.close()
            }))
        newWindow?.makeKeyAndOrderFront(nil)
    }
    
    private func openEditUtilityWindow(item: ShortcutObject) {
        if nil == newWindow {
            newWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 320, height: 500),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            newWindow?.center()
            newWindow?.setFrameAutosaveName("Utilities")
            newWindow?.isReleasedWhenClosed = false
            switch item.utilityType {
            case .commandline:
                newWindow?.contentView = NSHostingView(rootView: NewBashUtilityView(item: item, delegate: viewModel) {
                    newWindow?.close()
                })
            case .multiselection:
                newWindow?.contentView = NSHostingView(rootView: NewMultiSelectionUtilityView(item: item, delegate: viewModel) {
                    newWindow?.close()
                })
            case .none:
                break
            }
            
        }
        switch item.utilityType {
        case .commandline:
            newWindow?.contentView = NSHostingView(rootView: NewBashUtilityView(item: item, delegate: viewModel){
                newWindow?.close()
            })
        case .multiselection:
            newWindow?.contentView = NSHostingView(rootView: NewMultiSelectionUtilityView(item: item, delegate: viewModel) {
                newWindow?.close()
            })
        case .none:
            break
        }
        newWindow?.makeKeyAndOrderFront(nil)
    }
}
