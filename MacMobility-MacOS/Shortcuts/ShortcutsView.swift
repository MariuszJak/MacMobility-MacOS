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
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 6) {
                    ForEach(0..<30) { index in
                        VStack {
                            if let object = viewModel.objectAt(index: index) {
                                Text(object.title)
                                    .onDrag {
                                        NSItemProvider(object: object.id as NSString)
                                    }
                            }
                        }
                        .frame(width: 80, height: 80)
                        .background(
                            RoundedRectangle(cornerRadius: 20.0)
                                .fill(Color.black.opacity(0.4))
                        )
                        .onDrop(of: [.text], isTargeted: nil) { providers in
                            providers.first?.loadObject(ofClass: NSString.self) { (droppedItem, _) in
                                if let droppedString = droppedItem as? String, let object = viewModel.object(for: droppedString) {
                                    DispatchQueue.main.async {
                                        viewModel.addConfiguredShortcut(object: .init(index: index, id: object.id, title: object.title))
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
