//
//  SelectUtilityTypeWindowView.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 19/03/2025.
//

import SwiftUI

public struct UtilityObject: Identifiable {
    public let id: String = UUID().uuidString
    public enum UtilityType: String, Codable {
        case commandline
    }
    let type: UtilityType
    let title: String
    
    public init(type: UtilityType, title: String) {
        self.type = type
        self.title = title
    }
}

class SelectUtilityTypeWindowViewModel: ObservableObject {
    let connectionManager: ConnectionManager
    weak var delegate: UtilitiesWindowDelegate?
    
    @Published var utilities: [UtilityObject] = [
        .init(type: .commandline, title: "Commandline tool")
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
    let closeAction: () -> Void
    
    init(connectionManager: ConnectionManager, delegate: UtilitiesWindowDelegate?, closeAction: @escaping () -> Void) {
        self.connectionManager = connectionManager
        self.closeAction = closeAction
        self._viewModel = .init(wrappedValue: .init(connectionManager: connectionManager, delegate: delegate))
    }
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Select utility type")
                            .font(.system(size: 17.0, weight: .bold))
                            .padding([.horizontal, .top], 16)
                        Spacer()
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .onTapGesture {
                            }
                            .padding([.horizontal, .top], 16.0)
                    }
                    Divider()
                    if !viewModel.utilities.isEmpty {
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 240))], spacing: 6) {
                                ForEach(viewModel.utilities) { utility in
                                    VStack(alignment: .leading) {
                                        VStack(alignment: .leading) {
                                            HStack(alignment: .top) {
                                                Text(utility.title)
                                                    .lineLimit(1)
                                                    .font(.system(size: 16, weight: .bold))
                                                    .padding(.bottom, 8)
                                            }
                                            Divider()
                                            HStack {
                                                Image(systemName: "arrow.up.right.square")
                                                    .resizable()
                                                    .frame(width: 16, height: 16)
                                                    .onTapGesture {
                                                        closeAction()
                                                        openCreateNewUtilityWindow(type: utility.type)
                                                    }
                                                Image(systemName: "gear")
                                                    .resizable()
                                                    .frame(width: 16, height: 16)
                                                    .onTapGesture {
                                                    }
                                                Image(systemName: "trash")
                                                    .resizable()
                                                    .frame(width: 16, height: 16)
                                                    .onTapGesture {
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
                                        .padding(.bottom, 12.0)
                                    Button {
                                    } label: {
                                        Text("Add new one!")
                                            .font(.system(size: 16.0))
                                    }
                                }
                                Spacer()
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
        .padding()
    }
    
    private func openCreateNewUtilityWindow(type: UtilityObject.UtilityType, item: ShortcutObject? = nil) {
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
            switch type {
            case .commandline:
                newWindow?.contentView = NSHostingView(rootView: NewBashUtilityView(item: item, delegate: viewModel.delegate) {
                    newWindow?.close()
                })
            }
            
        }
        switch type {
        case .commandline:
            newWindow?.contentView = NSHostingView(rootView: NewBashUtilityView(item: item, delegate: viewModel.delegate){
                newWindow?.close()
            })
        }
        newWindow?.makeKeyAndOrderFront(nil)
    }
}
