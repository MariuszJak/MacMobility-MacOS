//
//  QuickActionsView.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 15/06/2025.
//

import Foundation
import SwiftUI

class QuickActionsViewModel: ObservableObject {
    @Published var items: [ShortcutObject] = []
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
                if item.id == object.id || item.title == object.title {
                    items[i] = .empty(for: i)
                }
            }
            var tmp = object
            tmp.index = newIndex
            items[newIndex] = tmp
        }
    }
}

struct QuickActionsView: View {
    @ObservedObject private var viewModel: QuickActionsViewModel
    @State private var hoveredIndex: Int? = nil
    @State private var isVisible: Bool = false
    let buttonCount = 10
    let cornerRadius = 20.0
    let radius: CGFloat = 100
    let action: (ShortcutObject) -> Void
    let update: ([ShortcutObject]) -> Void
    let frame = CGSize(width: 40, height: 40)
    
    init(
        viewModel: QuickActionsViewModel,
        action: @escaping (ShortcutObject) -> Void,
        update: @escaping ([ShortcutObject]) -> Void
    ) {
        self.viewModel = viewModel
        self.action = action
        self.update = update
    }

    var body: some View {
        ZStack {
            ForEach(Array(viewModel.items.enumerated()), id: \.offset) { (index, item) in
                let angle = Angle.degrees(Double(index) / Double(buttonCount) * 360)
                ZStack {
                    if index == item.index, item.id != "EMPTY \(index)" {
                        itemView(object: item)
                            .scaleEffect(index == hoveredIndex ? 1.3 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: index == hoveredIndex)
                            .onTapGesture {
                                action(item)
                            }
                            .onHover { hovering in
                                hoveredIndex = hovering ? index : (hoveredIndex == index ? nil : hoveredIndex)
                            }
                            
                    } else {
                        PlusButtonView(size: frame)
                            .frame(width: frame.width, height: frame.height)
                            .onTapGesture {
                                NotificationCenter.default.post(
                                    name: .openShortcuts,
                                    object: nil,
                                    userInfo: nil
                                )
                            }
                    }
                }
                .onDrop(of: [.text], isTargeted: nil) { providers in
                    providers.first?.loadObject(ofClass: NSString.self) { (droppedItem, _) in
                        if let droppedString = droppedItem as? String, let object = viewModel.object(for: droppedString) {
                            DispatchQueue.main.async {
                                viewModel.add(object, at: index)
                                update(viewModel.items)
                            }
                        }
                    }
                    return true
                }
                .offset(x: cos(angle.radians) * radius,
                        y: sin(angle.radians) * radius)
            }
            Image(systemName: "gear")
                .resizable()
                .frame(width: 20, height: 20)
                .padding(40)
                .background(Circle().stroke(Color.primary.opacity(0.3), lineWidth: 1))
                .contentShape(Circle())
                .onTapGesture {
                    NotificationCenter.default.post(
                        name: .openShortcuts,
                        object: nil,
                        userInfo: nil
                    )
                }
        }
        .frame(width: 2 * radius + 80, height: 2 * radius + 80)
        .background(.ultraThinMaterial)
        .clipShape(Circle())
        .scaleEffect(isVisible ? 1.0 : 0.6)
        .opacity(isVisible ? 1.0 : 0.0)
        .onAppear {
            for window in NSApplication.shared.windows {
                window.appearance = NSAppearance(named: .darkAqua)
            }
            withAnimation(.easeInOut) {
                isVisible = true
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

struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        view.isEmphasized = true
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
