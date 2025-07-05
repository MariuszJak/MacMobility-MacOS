//
//  QuickActionsView.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 15/06/2025.
//

import Foundation
import SwiftUI

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
            circleMainView()
            if showPopup {
                submenuPopup()
            }
            innerCircleMenu()
        }
        .scaleEffect(isVisible ? 1.0 : 0.6)
        .opacity(isVisible ? 1.0 : 0.0)
        .frame(width: 460, height: 460)
        .onAppear {
            for window in NSApplication.shared.windows {
                window.appearance = NSAppearance(named: .darkAqua)
            }
            withAnimation(.easeInOut) {
                isVisible = true
            }
        }
    }
    
    private func innerCircleMenu() -> some View {
        VStack {
            ZStack {
                Circle()
                    .fill(elegantGray)
                    .frame(width: 150, height: 150)
                    .onHover { _ in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            if !self.isEditing {
                                self.showPopup = false
                            }
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
                } else {
                    VStack {
                        HStack {
                            Button("<") {
                                viewModel.prevPage()
                            }
                            Text("Page: \(viewModel.currentPage)")
                            Button(">") {
                                viewModel.nextPage()
                            }
                        }
                        Divider()
                            .frame(width: 30)
                        HStack {
                            Button("+") {
                                viewModel.addPage()
                                update(viewModel.items)
                            }
                            Button("-") {
                                viewModel.removePage(with: viewModel.currentPage)
                                update(viewModel.items)
                            }
                        }
                        
                    }
                }
            }
        }
    }
    
    private func circleMainView() -> some View {
        ZStack {
            ForEach(Array(viewModel.items.filter { $0.page == viewModel.currentPage }.enumerated()), id: \.offset) { (index, item) in
                let angle = Angle.degrees(Double(index) / Double(buttonCount) * 360)
                CircleSliceBackground(index: index, sliceAngle: sliceAngle, thickness: 60)
                CircleSlice(index: index, sliceAngle: sliceAngle, thickness: 60)
                    .scaleEffect(index == hoveredIndex ? 1.05 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: index == hoveredIndex)
                ZStack {
                    if index + ((viewModel.currentPage - 1) * 10) == item.index, item.title != "EMPTY" {
                        mainView(item: item, index: index, angle: angle)
                    } else {
                        plusView(angle: angle, item: item)
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
    }
    
    private func submenuPopup() -> some View {
        ZStack {
            if let subitem, let objects = subitem.objects, objects.contains(where: { $0.title != "EMPTY" || isEditing }) {
                ForEach(Array(objects.enumerated()), id: \.offset) { (index, item) in
                    CircleSliceShape(
                        startAngle: .degrees(submenuDegrees),
                        sliceAngle: .degrees(sliceAngle),
                        thickness: 60
                    )
                    .fill(.cyan)
                    .rotationEffect(.degrees(Double(index) * sliceAngle))
                    CircleSliceShape(
                        startAngle: .degrees(submenuDegrees),
                        sliceAngle: .degrees(sliceAngle),
                        thickness: 60
                    )
                    .stroke(Color.black.opacity(0.5), lineWidth: 0.7)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 44/255, green: 44/255, blue: 46/255),   // Graphite Gray
                                Color(red: 58/255, green: 58/255, blue: 60/255)    // Steel Gray
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .rotationEffect(.degrees(Double(index) * sliceAngle))
                    .scaleEffect(index == hoveredSubIndex ? 1.05 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: index == hoveredSubIndex)
                    ZStack {
                        if let object = objects[safe: index], object.id != "EMPTY \(index)" {
                            submenuMainView(object: object, subitem: subitem, index: index)
                        } else {
                            PlusButtonView(size: frame, cornerRadius: 10)
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
        .frame(width: 430, height: 430)
        .scaleEffect(subMenuIsVisible ? 1.0 : 0.6)
        .opacity(subMenuIsVisible ? 1.0 : 0.0)
        .onAppear {
            subMenuIsVisible = true
        }
    }
    
    private func plusView(angle: Angle, item: ShortcutObject) -> some View {
        PlusButtonView(size: frame, cornerRadius: 10)
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
    
    private func submenuMainView(object: ShortcutObject, subitem: ShortcutObject, index: Int) -> some View {
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
    }
    
    private func mainView(item: ShortcutObject, index: Int, angle: Angle) -> some View {
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
