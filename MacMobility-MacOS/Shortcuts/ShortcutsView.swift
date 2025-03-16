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
                                        viewModel.addConfiguredShortcut(object: .init(index: index,
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
                .padding(.horizontal)
            }
            .scrollIndicators(.hidden)
            .frame(minWidth: 600, minHeight: 500)
            
            VStack(alignment: .leading) {
                TextField("Search...", text: $viewModel.searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.vertical, 16.0)
                ScrollView {
                    ForEach(viewModel.shortcuts) { shortcut in
                        HStack {
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
    }
}
