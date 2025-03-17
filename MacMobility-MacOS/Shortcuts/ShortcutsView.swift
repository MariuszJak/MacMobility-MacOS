//
//  ShortcutsView.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 16/03/2025.
//

import SwiftUI

struct ShortcutsView: View {
    @ObservedObject private var viewModel: ShortcutsViewModel
    
    
    init(viewModel: ShortcutsViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Shortcuts Editor")
                    .font(.system(size: 17.0, weight: .bold))
                    .padding([.horizontal, .top], 16)
                
                Image(systemName: "plus.circle.fill")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .padding([.horizontal, .top], 16.0)
            }
            Divider()
        }
        HStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 6) {
                    ForEach(0..<42) { index in
                        VStack {
                            if let object = viewModel.objectAt(index: index) {
                                if let path = object.path, object.type == .app {
                                    ZStack {
                                        Image(nsImage: NSWorkspace.shared.icon(forFile: path))
                                            .resizable()
                                            .frame(width: 80, height: 80)
                                            .cornerRadius(20)
                                            
                                        VStack {
                                            HStack {
                                                Spacer()
                                                RedXButton {
                                                    viewModel.removeShortcut(id: object.id)
                                                }
                                            }
                                            Spacer()
                                        }
                                    }
                                } else if object.type == .shortcut {
                                    ZStack {
                                        Text(object.title)
                                            .font(.system(size: 12))
                                            .multilineTextAlignment(.center)
                                            .padding(.all, 3)
                                            
                                        VStack {
                                            HStack {
                                                Spacer()
                                                RedXButton {
                                                    viewModel.removeShortcut(id: object.id)
                                                }
                                            }
                                            Spacer()
                                        }
                                    }
                                }
                            }
                        }
                        .frame(width: 70, height: 70)
                        .background(
                            RoundedRectangle(cornerRadius: 20.0)
                                .fill(viewModel.objectAt(index: index)?.color.let { Color(hex: $0) } ?? Color.black.opacity(0.4))
                        )
                        .ifLet(viewModel.objectAt(index: index)?.id) { view, id in
                            view.onDrag {
                                NSItemProvider(object: id as NSString)
                            }
                        }
                        .onDrop(of: [.text], isTargeted: nil) { providers in
                            providers.first?.loadObject(ofClass: NSString.self) { (droppedItem, _) in
                                if let droppedString = droppedItem as? String, let object = viewModel.object(for: droppedString) {
                                    DispatchQueue.main.async {
                                        viewModel.addConfiguredShortcut(object: .init(type: object.type,
                                                                                      index: index,
                                                                                      path: object.path,
                                                                                      id: object.id,
                                                                                      title: object.title,
                                                                                      color: object.color))
                                    }
                                }
                            }
                            return true
                        }
                    }
                }
                .padding([.horizontal, .top])
            }
            .scrollIndicators(.hidden)
            .frame(minWidth: 600, minHeight: 500)
            VStack {
                TextField("Search...", text: $viewModel.searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding([.horizontal, .bottom], 16.0)
                TabView {
                    shortcutsView
                        .tabItem( { Text("Shortcuts") })
                    installedAppsView
                        .tabItem( { Text("Applications") })
                }
                .tabViewStyle(.automatic)
                .padding([.horizontal, .bottom])
            }
        }
    }
    
    private var shortcutsView: some View {
        VStack(alignment: .leading) {
            ScrollView {
                ForEach(viewModel.shortcuts) { shortcut in
                    HStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: shortcut.color ?? ""))
                            .frame(width: 44, height: 44)
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
                                .cornerRadius(3)
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
}
