//
//  QuickActionsViewSetup.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 15/06/2025.
//

import Foundation
import SwiftUI

struct QuicActionMenuSetupView: View {
    let setupViewModel: QuickActionsViewSetupModel
    let action: ([ShortcutObject]?, Bool) -> Void
    
    init(setupViewModel: QuickActionsViewSetupModel, action: @escaping ([ShortcutObject]?, Bool) -> Void) {
        self.setupViewModel = setupViewModel
        self.action = action
    }
    
    var body: some View {
        VStack(alignment: .center) {
            Text("Quick Action Menu")
                .font(.system(size: 18.0, weight: .bold))
            Text("To open Quick Action Menu, press Control + Option + Space.")
                .font(.system(size: 14.0, weight: .medium))
        }
        VStack {
            QuickActionsViewSetup(viewModel: setupViewModel)
        }
        .padding()
        HStack {
            BlueButton(title: "Cancel", font: .callout, padding: 12.0, backgroundColor: .gray) {
                action(nil, true)
            }
            .padding(.trailing, 6.0)
            BlueButton(title: "Update", font: .callout, padding: 12.0) {
                action(setupViewModel.items, false)
            }
            BlueButton(title: "Update & Close", font: .callout, padding: 12.0) {
                action(setupViewModel.items, true)
            }
        }
        .padding(.trailing, 6.0)
    }
}

class QuickActionsViewSetupModel: ObservableObject {
    @Published var items: [ShortcutObject] = []
    @Published var buttonCount = 10
    private let allItems: [ShortcutObject]
    
    init(items: [ShortcutObject], allItems: [ShortcutObject]) {
        self.items = items
        self.allItems = allItems
    }
    
    func object(for id: String) -> ShortcutObject? {
        (allItems + items).first { $0.id == id }
    }
    
    func add(_ object: ShortcutObject, at newIndex: Int = 0) {
        if let oldIndex = items.firstIndex(where: { $0.id == object.id && items[newIndex].title != "EMPTY" }) {
            let oldObject = items[newIndex]
            var tmp = object
            tmp.index = newIndex
            items[newIndex] = tmp
            
            var tmp2 = oldObject
            tmp2.index = oldIndex
            items[oldIndex] = tmp2
        } else {
            items.enumerated().forEach { (i, item) in
                if item.id == object.id {
                    items[i] = .empty(for: i)
                }
            }
            var tmp = object
            tmp.index = newIndex
            items[newIndex] = tmp
        }
    }
    
    func remove(at index: Int) {
        items[index] = .empty(for: index)
    }
}

struct QuickActionsViewSetup: View {
    @ObservedObject private var viewModel: QuickActionsViewSetupModel
    
    let cornerRadius = 30.0
    let radius: CGFloat = 100
    let frame = CGSize(width: 50, height: 50)
    
    init(viewModel: QuickActionsViewSetupModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            ForEach(Array(viewModel.items.enumerated()), id: \.offset) { (index, item) in
                let angle = Angle.degrees(Double(index) / Double(viewModel.buttonCount) * 360)
                VStack {
                    if index == item.index, item.id != "EMPTY \(index)" {
                        ZStack {
                            itemView(object: item)
                                .onDrag {
                                    NSItemProvider(object: item.id as NSString)
                                }
                            VStack {
                                HStack {
                                    Spacer()
                                    RedXButton {
                                        viewModel.remove(at: index)
                                    }
                                }
                                Spacer()
                            }
                        }
                        .frame(width: frame.width, height: frame.height)
                    } else {
                        PlusButtonView(size: frame)
                    }
                }
                .onDrop(of: [.text], isTargeted: nil) { providers in
                    providers.first?.loadObject(ofClass: NSString.self) { (droppedItem, _) in
                        if let droppedString = droppedItem as? String, let object = viewModel.object(for: droppedString) {
                            DispatchQueue.main.async {
                                viewModel.add(object, at: index)
                            }
                        }
                    }
                    return true
                }
                .offset(x: cos(angle.radians) * radius,
                        y: sin(angle.radians) * radius)
                
            }
        }
        .frame(width: 2 * radius + 80, height: 2 * radius + 80)
        .background(
            VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                .clipShape(Circle())
                .opacity(0.9)
        )
        .onAppear {
            for window in NSApplication.shared.windows {
                window.appearance = NSAppearance(named: .darkAqua)
            }
        }
    }
    
    @ViewBuilder
    private func itemView(object: ShortcutObject) -> some View {
        if let path = object.path, object.type == .app {
            Image(nsImage: NSWorkspace.shared.icon(forFile: path))
                .resizable()
                .scaledToFill()
                .frame(width: frame.width, height: frame.height)
        } else if object.type == .shortcut {
            if let data = object.imageData, let image = NSImage(data: data) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .cornerRadius(cornerRadius)
                    .frame(width: frame.width, height: frame.height)
            }
            if object.showTitleOnIcon ?? true {
                Text(object.title)
                    .font(.system(size: 12))
                    .multilineTextAlignment(.center)
                    .padding(.all, 3)
                    .outlinedText()
            }
        } else if object.type == .webpage {
            if let data = object.imageData, let image = NSImage(data: data) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .cornerRadius(cornerRadius)
                    .frame(width: frame.width, height: frame.height)
                    .clipShape(
                        RoundedRectangle(cornerRadius: cornerRadius)
                    )
                if object.showTitleOnIcon ?? true {
                    Text(object.title)
                        .font(.system(size: 12))
                        .multilineTextAlignment(.center)
                        .padding(.all, 3)
                        .outlinedText()
                }
            } else if let path = object.browser?.icon {
                Image(path)
                    .resizable()
                    .frame(width: frame.width, height: frame.height)
                    .cornerRadius(cornerRadius)
                if object.showTitleOnIcon ?? true {
                    Text(object.title)
                        .font(.system(size: 12))
                        .multilineTextAlignment(.center)
                        .padding(.all, 3)
                        .outlinedText()
                }
            }
        } else if object.type == .utility {
            if let data = object.imageData, let image = NSImage(data: data) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .cornerRadius(cornerRadius)
                    .frame(width: frame.width, height: frame.height)
            }
            if !object.title.isEmpty {
                if object.showTitleOnIcon ?? true {
                    Text(object.title)
                        .font(.system(size: 11))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(maxWidth: 80)
                        .outlinedText()
                }
            }
        } else if object.type == .html {
            if let data = object.imageData, let image = NSImage(data: data) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .cornerRadius(cornerRadius)
                    .frame(width: frame.width, height: frame.height)
            }
            if !object.title.isEmpty {
                if object.showTitleOnIcon ?? true {
                    Text(object.title)
                        .font(.system(size: 11))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(maxWidth: 80)
                        .outlinedText()
                }
            }
        }
    }
}
