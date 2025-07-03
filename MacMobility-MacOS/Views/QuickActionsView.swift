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
            
            if items[newIndex].objects == nil {
                items[newIndex].objects = (0..<5).map { .empty(for: $0) }
            }
            
            var tmp2 = oldObject
            tmp2.index = oldIndex
            items[oldIndex] = tmp2
            
            if items[oldIndex].objects == nil {
                items[oldIndex].objects = (0..<5).map { .empty(for: $0) }
            }
        } else {
            var objects: [ShortcutObject]?
            if let oldIndex = items.firstIndex(where: { $0.id == object.id }) {
                objects = items[oldIndex].objects
            }
            items.enumerated().forEach { (i, item) in
                if item.id == object.id {
                    items[i] = .empty(for: i)
                    items[i].objects = (0..<5).map { .empty(for: $0) }
                }
            }
            var tmp = object
            tmp.index = newIndex
            items[newIndex] = tmp
            if items[newIndex].objects == nil {
                items[newIndex].objects = objects ?? (0..<5).map { .empty(for: $0) }
            }
        }
    }
    
    func addSubitem(to itemId: String, item: ShortcutObject, at subIndex: Int) -> ShortcutObject? {
        if let index = items.firstIndex(where: { $0.id == itemId }), items[index].title != "EMPTY" {
            if items[index].objects == nil {
                items[index].objects = (0..<5).map { .empty(for: $0) }
            }
            items[index].objects?[subIndex] = item
            return items[index]
        } else {
            return nil
        }
    }
    
    func removeSubitem(from itemId: String, at subIndex: Int) -> ShortcutObject? {
        if let index = items.firstIndex(where: { $0.id == itemId }) {
            items[index].objects?[subIndex] = .empty(for: subIndex)
            return items[index]
        }
        return nil
    }
    
    func remove(at index: Int) -> ShortcutObject {
        items[index] = .empty(for: index)
        items[index].objects = (0..<5).map { .empty(for: $0) }
        return items[index]
    }
}

struct QuickActionsView: View {
    @ObservedObject private var viewModel: QuickActionsViewModel
    @State private var hoveredIndex: Int? = nil
    @State private var hoveredSubIndex: Int? = nil
    @State private var isVisible: Bool = false
    @State private var subMenuIsVisible: Bool = false
    @State private var isEditing: Bool = false
    @State private var showPopup = false
    let buttonCount = 10
    let cornerRadius = 20.0
    let radius: CGFloat = 120
    let action: (ShortcutObject) -> Void
    let update: ([ShortcutObject]) -> Void
    let frame = CGSize(width: 40, height: 40)
    let thickness: CGFloat = 60
    let elegantGray = Color(red: 0.3, green: 0.3, blue: 0.33)
    let sliceCount = 10
    let sliceAngle = 360.0 / 10.0
    @State var submenuDegrees = 0.0
    @State var subitem: ShortcutObject?
    
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
            ZStack {
                ForEach(Array(viewModel.items.enumerated()), id: \.offset) { (index, item) in
                    let angle = Angle.degrees(Double(index) / Double(buttonCount) * 360)
                    CircleSlice(index: index, sliceAngle: sliceAngle, thickness: 60)
                        .scaleEffect(index == hoveredIndex ? 1.05 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: index == hoveredIndex)
                    ZStack {
                        if index == item.index, item.id != "EMPTY \(index)" {
                            ZStack {
                                itemView(object: item)
                                    .if(!isEditing) {
                                        $0.scaleEffect(index == hoveredIndex ? 1.3 : 1.0)
                                            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: index == hoveredIndex)
                                            .onTapGesture {
                                                action(item)
                                            }
                                            .contextMenu {
                                                Button("Edit") {
                                                    isEditing = true
                                                    NotificationCenter.default.post(
                                                        name: .openShortcuts,
                                                        object: nil,
                                                        userInfo: nil
                                                    )
                                                }
                                            }
                                            .onHover { hovering in
                                                hoveredIndex = hovering ? index : (hoveredIndex == index ? nil : hoveredIndex)
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                                    submenuDegrees = angle.degrees - 92
                                                    if hovering {
                                                        showPopup = true
                                                    }
                                                    subitem = item
                                                }
                                            }
                                    }
                                    .if(isEditing) {
                                        $0.onHover { hovering in
                                            showPopup = true
                                            submenuDegrees = angle.degrees - 92
                                            subitem = item
                                        }
                                    }
                                    .shadow(color: .black.opacity(0.6), radius: 4.0)
                                if isEditing {
                                    VStack {
                                        HStack {
                                            Spacer()
                                            RedXButton {
                                                subitem = viewModel.remove(at: index)
                                                update(viewModel.items)
                                            }
                                        }
                                        Spacer()
                                    }
                                }
                            }
                            .frame(width: 60.0, height: 60.0)
                        } else {
                            PlusButtonView(size: frame)
                                .frame(width: frame.width, height: frame.height)
                                .onTapGesture {
                                    isEditing = true
                                    showPopup = true
                                    submenuDegrees = angle.degrees - 92
                                    subitem = item
                                    NotificationCenter.default.post(
                                        name: .openShortcuts,
                                        object: nil,
                                        userInfo: nil
                                    )
                                }
                                .onHover { _ in
                                    if !isEditing {
                                        showPopup = false
                                    } else {
                                        submenuDegrees = angle.degrees - 92
                                        subitem = item
                                        showPopup = true
                                    }
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
                    .offset(x: cos(angle.radians) * (radius * (index == hoveredIndex ? 1.05 : 1.0)),
                            y: sin(angle.radians) * (radius * (index == hoveredIndex ? 1.05 : 1.0)))
                    .zIndex(1000)
                }
            }
            .frame(width: 300, height: 300)
            if showPopup {
                ZStack {
                    if let subitem, let objects = subitem.objects, objects.contains(where: { $0.title != "EMPTY" || isEditing }) {
                        ForEach(Array(objects.enumerated()), id: \.offset) { (index, item) in
                            CircleSliceShape(
                                startAngle: .degrees(submenuDegrees),
                                sliceAngle: .degrees(sliceAngle),
                                thickness: 55
                            )
                            .stroke(Color.black.opacity(0.5), lineWidth: 0.7)
                            .fill(Color.cyan)
                            .rotationEffect(.degrees(Double(index) * sliceAngle))
                            ZStack {
                                if let object = objects[safe: index], object.id != "EMPTY \(index)" {
                                    ZStack {
                                        itemView(object: object)
                                            .if(!isEditing) {
                                                $0.scaleEffect(index == hoveredSubIndex ? 1.3 : 1.0)
                                                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: index == hoveredSubIndex)
                                                    .onTapGesture {
                                                        action(object)
                                                    }
                                                    .contextMenu {
                                                        Button("Edit") {
                                                           isEditing = true
                                                            NotificationCenter.default.post(
                                                                name: .openShortcuts,
                                                                object: nil,
                                                                userInfo: nil
                                                            )
                                                        }
                                                    }
                                                    .onHover { hovering in
                                                        hoveredSubIndex = hovering ? index : (hoveredSubIndex == index ? nil : hoveredSubIndex)
                                                    }
                                            }
                                            .shadow(color: .black.opacity(0.6), radius: 4.0)
                                        if isEditing {
                                            VStack {
                                                HStack {
                                                    Spacer()
                                                    RedXButton {
                                                        if let updatedItem = viewModel.removeSubitem(from: subitem.id, at: index) {
                                                            self.subitem = updatedItem
                                                        }
                                                        update(viewModel.items)
                                                    }
                                                }
                                                Spacer()
                                            }
                                        }
                                    }
                                    .frame(width: 60.0, height: 60.0)
                                } else {
                                    PlusButtonView(size: frame)
                                        .frame(width: frame.width, height: frame.height)
                                        .onTapGesture {
                                            isEditing = true
                                            NotificationCenter.default.post(
                                                name: .openShortcuts,
                                                object: nil,
                                                userInfo: nil
                                            )
                                        }
                                        .opacity(subitem.title == "EMPTY" ? 0.3 : 1.0)
                                }
                            }
                            .onDrop(of: [.text], isTargeted: nil) { providers in
                                providers.first?.loadObject(ofClass: NSString.self) { (droppedItem, _) in
                                    if let droppedString = droppedItem as? String,
                                       let object = viewModel.object(for: droppedString) {
                                        DispatchQueue.main.async {
                                            if let updatedItem = viewModel.addSubitem(to: subitem.id, item: object, at: index) {
                                                self.subitem = updatedItem
                                            }
                                            update(viewModel.items)
                                           
                                        }
                                    }
                                }
                                return true
                            }
                            .offset(x: cos(Angle.degrees((submenuDegrees + 20) + (35.0 * Double(index))).radians) * 185,
                                    y: sin(Angle.degrees((submenuDegrees + 20) + (35.0 * Double(index))).radians) * 185)
                        }
                    }
                    
                }
                .frame(width: 420, height: 420)
                .scaleEffect(subMenuIsVisible ? 1.0 : 0.6)
                .opacity(subMenuIsVisible ? 1.0 : 0.0)
                .onAppear {
                    subMenuIsVisible = true
                }
            }
            VStack {
                ZStack {
                    Circle()
                        .fill(elegantGray)
                        .frame(width: 150, height: 150)
                        .onHover { _ in
                            if !isEditing {
                                showPopup = false
                            }
                        }
                    if isEditing {
                        Button("Save") {
                            isEditing = false
                            NotificationCenter.default.post(
                                name: .closeShortcuts,
                                object: nil,
                                userInfo: nil
                            )
                        }
                    }
                }
            }
        }
        .scaleEffect(isVisible ? 1.0 : 0.6)
        .opacity(isVisible ? 1.0 : 0.0)
        .frame(width: 420, height: 420)
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

struct CircleSlice: View {
    let index: Int
    let sliceAngle: Double
    let thickness: CGFloat
    let elegantGray = Color(red: 0.3, green: 0.3, blue: 0.33)

    var startAngle: Angle { .degrees(-20) }
    var rotation: Angle { .degrees(Double(index) * sliceAngle) }

    var body: some View {
        let sliceShape = CircleSliceShape(
            startAngle: startAngle,
            sliceAngle: .degrees(sliceAngle),
            thickness: thickness
        )

        return sliceShape
            .fill(LinearGradient(
                gradient: Gradient(colors: [.blue, .cyan]),
                startPoint: .top,
                endPoint: .bottom))
            .rotationEffect(rotation)
            .overlay {
                sliceShape
                    .stroke(Color.black.opacity(0.2), lineWidth: 0.5)
                    .rotationEffect(rotation)
            }
            .contentShape(sliceShape)
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

struct CircleSliceShape: Shape {
    var startAngle: Angle = .degrees(-15)
    var sliceAngle: Angle = .degrees(36)
    var thickness: CGFloat = 50

    func path(in rect: CGRect) -> Path {
        let radius = min(rect.width, rect.height) / 2
        let innerRadius = radius - thickness
        let center = CGPoint(x: rect.midX, y: rect.midY)

        let endAngle = startAngle + sliceAngle

        var path = Path()
        
        // Outer arc
        path.addArc(center: center,
                    radius: radius,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: false)

        // Line to inner arc
        path.addArc(center: center,
                    radius: innerRadius,
                    startAngle: endAngle,
                    endAngle: startAngle,
                    clockwise: true)

        path.closeSubpath()
        return path
    }
}
