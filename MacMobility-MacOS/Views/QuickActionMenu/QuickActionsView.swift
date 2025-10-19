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
    
    @State private var isVisible: Bool = false
    @State private var subMenuIsVisible: Bool = false
    
    private let buttonCount = 10
    private let cornerRadius = 20.0
    private let radius: CGFloat = 120
    private let update: ([ShortcutObject]) -> Void
    private let close: () -> Void
    private let frame = CGSize(width: 40, height: 40)
    private let thickness: CGFloat = 60
    private let elegantGray = Color(red: 58/255, green: 58/255, blue: 60/255)
    private let sliceCount = 10
    private let sliceAngle = 360.0 / 10.0
    
    private var innerCircleColors: [Color] {
        [
            Color(red: 44/255, green: 44/255, blue: 46/255),
            Color(red: 44/255, green: 44/255, blue: 46/255),
            Color(red: 44/255, green: 44/255, blue: 46/255),
            Color(red: 44/255, green: 44/255, blue: 46/255),
            viewModel.isEditing ? Color(red: 58/255, green: 58/255, blue: 60/255) : Color(red: 44/255, green: 44/255, blue: 46/255),
            Color(red: 58/255, green: 58/255, blue: 60/255)
        ]
    }
    
    private var innerCircleActions: [(() -> Void)?] {
        [
            {
                viewModel.nextPage()
                viewModel.showPopup = false
                viewModel.isTabPressed = false
            },
            {
                viewModel.addPage()
                update(viewModel.items)
            },
            {
                viewModel.removePage(with: viewModel.currentPage)
                update(viewModel.items)
            },
            {
                viewModel.prevPage()
                viewModel.showPopup = false
                viewModel.isTabPressed = false
            },
            {
                if !viewModel.isEditing {
                    NotificationCenter.default.post(
                        name: .openNewQAMTutorial,
                        object: nil,
                        userInfo: nil
                    )
                }
            },
            nil
        ]
    }
    
    private var innerCirlceContents: [() -> AnyView] {
        [
            { AnyView(Text(">").allowsHitTesting(false)) },
            { AnyView(Text("+").allowsHitTesting(false)) },
            { AnyView(Text("-").allowsHitTesting(false)) },
            { AnyView(Text("<").allowsHitTesting(false)) },
            {
                if viewModel.isEditing {
                    AnyView(EmptyView())
                } else {
                    AnyView(Image(systemName: "info.circle").frame(width: 10, height: 10).allowsHitTesting(false))
                }
            },
            { AnyView(Text("")) },
        ]
    }
    
    init(
        viewModel: QuickActionsViewModel,
        update: @escaping ([ShortcutObject]) -> Void,
        close: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.update = update
        self.close = close
    }
    
    var body: some View {
        ZStack {
            Color.white.opacity(0.001)
                .contentShape(Rectangle())
                .onTapGesture {
                    close()
                }
            circleMainView()
            if viewModel.showPopup {
                submenuPopup()
            }
            innerCircleMenu()
        }
        .scaleEffect(isVisible ? 1.0 : 0.6)
        .opacity(isVisible ? 1.0 : 0.0)
        .frame(width: 460, height: 460)
        .onAppear {
            withAnimation(.easeInOut) {
                isVisible = true
            }
        }
    }
    
    var circularDotsRotation: Angle {
        if viewModel.pages == 2 {
            return .degrees(270)
        } else {
            return .degrees(180)
        }
    }
    
    @ViewBuilder
    private func pageNumberView(page: Int) -> some View {
        VStack {
            if let assignedApp = viewModel.getAssigned(to: page),
               let app = viewModel.object(path: assignedApp.appPath) {
                if let data = viewModel.getIcon(fromAppPath: assignedApp.appPath),
                   let image = NSImage(data: data) {
                    ZStack {
                        VStack {
                            ZStack {
                                ZStack {
//                                    EventView { direction in
//                                        viewModel.handleDirection(direction)
//                                    }
                                    Image(nsImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .cornerRadius(cornerRadius)
                                }
                                .frame(width: 60, height: 60)
                                .shadow(color: .black.opacity(0.6), radius: 4.0)
                                .if(!viewModel.isEditing) {
                                    $0.onTapGesture {
                                        viewModel.action(app)
                                    }
                                    .contextMenu {
                                        Button("Edit") {
                                            viewModel.isEditing = true
                                            NotificationCenter.default.post(
                                                name: .openShortcuts,
                                                object: nil,
                                                userInfo: nil
                                            )
                                        }
                                    }
                                }
                                if viewModel.isEditing {
                                    VStack {
                                        HStack {
                                            Spacer()
                                            RedXButton {
                                                viewModel.unassign(app: assignedApp.appPath, from: page)
                                            }
                                        }
                                        Spacer()
                                    }
                                }
                            }
                        }
                        .frame(width: 60, height: 60)
                        .onDrop(of: [.text], isTargeted: nil) { providers in
                            providers.first?.loadObject(ofClass: NSString.self) { (droppedItem, _) in
                                if let droppedString = droppedItem as? String,
                                   let object = viewModel.object(for: droppedString),
                                   object.type == .app,
                                   let path = object.path {
                                    DispatchQueue.main.async {
                                        viewModel.replace(app: path, to: page)
                                    }
                                }
                            }
                            return true
                        }
                        if !viewModel.isEditing {
                            CircularPageDotsView(
                                pageCount: viewModel.pages,
                                currentPage: viewModel.currentPage - 1
                            ) { index in
                                viewModel.set(page: index + 1)
                            }
                            .rotationEffect(circularDotsRotation)
                        }
                    }
                }
            } else {
                if !viewModel.isEditing {
                    ZStack {
                        ZStack {
//                            EventView { direction in
//                                viewModel.handleDirection(direction)
//                            }
                            Image(systemName: "slider.horizontal.3")
                                .resizable()
                                .frame(width: 20, height: 20)
                        }
                        .frame(width: 30, height: 30)
                        .onTapGesture {
                            viewModel.isEditing = true
                            NotificationCenter.default.post(
                                name: .openShortcuts,
                                object: nil,
                                userInfo: nil
                            )
                        }
                        .padding(.all, 10.0)
                        .background(
                            RoundedBackgroundView(cornerRadius: 10.0)
                        )
                        CircularPageDotsView(
                            pageCount: viewModel.pages,
                            currentPage: viewModel.currentPage - 1
                        ) { index in
                            viewModel.set(page: index + 1)
                        }
                        .rotationEffect(circularDotsRotation)
                    }
                } else {
                    RoundedTextButtonView(
                        higlightedText: "Page \(page)",
                        text: "Drop App Here",
                        size: .init(width: 60.0, height: 60.0),
                        cornerRadius: 10
                    )
                    .onDrop(of: [.text], isTargeted: nil) { providers in
                        providers.first?.loadObject(ofClass: NSString.self) { (droppedItem, _) in
                            if let droppedString = droppedItem as? String,
                               let object = viewModel.object(for: droppedString),
                               object.type == .app,
                                   let path = object.path {
                                    DispatchQueue.main.async {
                                        viewModel.assign(app: path, to: page)
                                    }
                                }
                            }
                            return true
                        }
                }
            }
        }
    }
    
    func selectApp() -> String? {
        let openPanel = NSOpenPanel()
        openPanel.title = "Select an Application"
        openPanel.allowedContentTypes = [.application]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        
        if openPanel.runModal() == .OK {
            return openPanel.url?.path
        }
        
        return nil
    }
    
    private func innerCircleMenu() -> some View {
        VStack {
            ZStack {
                ZStack {
                    ForEach(0..<6) { index in
                        switch index {
                        case 0:
                            SliceButton<AnyView>(
                                index: index,
                                totalSlices: 6,
                                thickness: 15,
                                color: viewModel.pages == 1 ? elegantGray : innerCircleColors[index],
                                action: innerCircleActions[index],
                                content: viewModel.pages == 1 ? {AnyView(EmptyView())} : innerCirlceContents[index]
                            )
                        case 2:
                            SliceButton<AnyView>(
                                index: index,
                                totalSlices: 6,
                                thickness: 15,
                                color: viewModel.pages == 1 ? elegantGray : innerCircleColors[index],
                                action: innerCircleActions[index],
                                content: viewModel.pages == 1 ? {AnyView(EmptyView())} : innerCirlceContents[index]
                            )
                        case 3:
                            SliceButton<AnyView>(
                                index: index,
                                totalSlices: 6,
                                thickness: 15,
                                color: viewModel.pages == 1 ? elegantGray : innerCircleColors[index],
                                action: innerCircleActions[index],
                                content: viewModel.pages == 1 ? {AnyView(EmptyView())} : innerCirlceContents[index]
                            )
                        default:
                            SliceButton<AnyView>(
                                index: index,
                                totalSlices: 6,
                                thickness: 15,
                                color: innerCircleColors[index],
                                action: innerCircleActions[index],
                                content: innerCirlceContents[index]
                            )
                        }
                    }
                }.frame(width: 150, height: 150)
                Circle()
                    .fill(elegantGray)
                    .onHover { _ in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            self.viewModel.showPopup = false
                            self.viewModel.subitem = nil
                            self.viewModel.isTabPressed = false
                        }
                    }
                    .contentShape(Circle())
                    .frame(width: 120, height: 120)
                    
                VStack {
                    if viewModel.isEditing {
                        VStack(spacing: 2.0) {
                            pageNumberView(page: viewModel.currentPage)
                            BlueButton(
                                title: "Close",
                                font: .callout,
                                padding: 3.0,
                                cornerRadius: 3.0,
                                backgroundColor: .accentColor
                            ) {
                                viewModel.isEditing = false
                                viewModel.showPopup = false
                                viewModel.isTabPressed = false
                                NotificationCenter.default.post(
                                    name: .closeShortcuts,
                                    object: nil,
                                    userInfo: nil
                                )
                            }
                            .padding(.top, 4.0)
                        }
                    } else {
                        VStack {
                            HStack {
                                pageNumberView(page: viewModel.currentPage)
                            }
                        }
                    }
                }
                .frame(height: 120)
            }
        }
    }
    
    private func circleMainView() -> some View {
        ZStack {
            ForEach(Array(viewModel.items.filter { $0.page == viewModel.currentPage }.enumerated()), id: \.offset) { (index, item) in
                let angle = Angle.degrees(Double(index) / Double(buttonCount) * 360)
                CircleSliceBackground(index: index, sliceAngle: sliceAngle, thickness: 60)
                CircleSlice(index: index, sliceAngle: sliceAngle, thickness: 60)
                    .scaleEffect(index == viewModel.hoveredIndex ? 1.05 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: index == viewModel.hoveredIndex)
                ZStack {
                    if index + ((viewModel.currentPage - 1) * 10) == item.index, item.title != "EMPTY" {
                        mainView(item: item, index: index, angle: angle)
                    } else {
                        plusView(angle: angle, item: item, index: index)
                    }
                }
                .offset(x: cos(angle.radians) * (radius * (index == viewModel.hoveredIndex ? 1.05 : 1.0)),
                        y: sin(angle.radians) * (radius * (index == viewModel.hoveredIndex ? 1.05 : 1.0)))
                .zIndex(1000)
            }
        }
        .frame(width: 300, height: 300)
    }
    
    private func submenuPopup() -> some View {
        ZStack {
            if let subitem = viewModel.subitem,
               let objects = subitem.objects,
               objects.contains(where: { $0.title != "EMPTY" || viewModel.isEditing }) {
                ForEach(Array(objects.enumerated()), id: \.offset) { (index, item) in
                    CircleSliceShape(
                        startAngle: .degrees(viewModel.submenuDegrees),
                        sliceAngle: .degrees(sliceAngle),
                        thickness: 60
                    )
                    .fill(.cyan)
                    .rotationEffect(.degrees(Double(index) * sliceAngle))
                    CircleSliceShape(
                        startAngle: .degrees(viewModel.submenuDegrees),
                        sliceAngle: .degrees(sliceAngle),
                        thickness: 60
                    )
                    .stroke(Color(red: 44/255, green: 44/255, blue: 46/255), lineWidth: 0.7)
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
                    .scaleEffect(index == viewModel.hoveredSubIndex ? 1.05 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: index == viewModel.hoveredSubIndex)
                    ZStack {
                        if let object = objects[safe: index], object.id != "EMPTY \(index)" {
                            submenuMainView(object: object, subitem: subitem, index: index)
                        } else {
                            PlusButtonView(size: frame, cornerRadius: 10, dropAction: { droppedItem in
                                if let droppedString = droppedItem as? String,
                                   let object = viewModel.object(for: droppedString) {
                                    DispatchQueue.main.async {
                                        if let updatedItem = viewModel.addSubitem(to: subitem.id, item: object, at: index) {
                                            self.viewModel.subitem = updatedItem
                                        }
                                        update(viewModel.items)
                                    }
                                }
                            })
                            .frame(width: frame.width, height: frame.height)
                            .onTapGesture {
                                viewModel.isEditing = true
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
                                        self.viewModel.subitem = updatedItem
                                    }
                                    update(viewModel.items)
                                }
                            }
                        }
                        return true
                    }
                    .offset(x: cos(Angle.degrees((viewModel.submenuDegrees + 20) + (35.0 * Double(index))).radians) * 185,
                            y: sin(Angle.degrees((viewModel.submenuDegrees + 20) + (35.0 * Double(index))).radians) * 185)
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
    
    private func plusView(angle: Angle, item: ShortcutObject, index: Int) -> some View {
        PlusButtonView(size: frame, cornerRadius: 10, dropAction: { droppedItem in
            if let droppedString = droppedItem as? String, let object = viewModel.object(for: droppedString) {
                DispatchQueue.main.async {
                    viewModel.add(object, at: index)
                    update(viewModel.items)
                }
            }
        })
        .frame(width: frame.width, height: frame.height)
        .onTapGesture {
            viewModel.isEditing = true
            viewModel.showPopup = true
            viewModel.submenuDegrees = angle.degrees - 92
            viewModel.subitem = item
            NotificationCenter.default.post(
                name: .openShortcuts,
                object: nil,
                userInfo: nil
            )
        }
        .onHover { _ in
            if !viewModel.isEditing {
                viewModel.showPopup = false
                viewModel.isTabPressed = false
                // lastHoveredIndex = nil
            } else {
                viewModel.submenuDegrees = angle.degrees - 92
                viewModel.subitem = item
                viewModel.showPopup = true
            }
        }
    }
    
    private func submenuMainView(object: ShortcutObject, subitem: ShortcutObject, index: Int) -> some View {
        ZStack {
            itemView(object: object)
                .if(!viewModel.isEditing) {
                    $0.scaleEffect(index == viewModel.hoveredSubIndex ? 1.3 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: index == viewModel.hoveredSubIndex)
                        .onTapGesture {
                            viewModel.action(object)
                        }
                        .contextMenu {
                            Button("Edit") {
                                viewModel.isEditing = true
                                NotificationCenter.default.post(
                                    name: .openShortcuts,
                                    object: nil,
                                    userInfo: nil
                                )
                            }
                        }
                        .onHover { hovering in
                            viewModel.hoveredSubIndex = hovering
                            ? index
                            : (viewModel.hoveredSubIndex == index
                               ? nil
                               : viewModel.hoveredSubIndex)
                        }
                }
                .shadow(color: .black.opacity(0.6), radius: 4.0)
            if viewModel.isEditing {
                VStack {
                    HStack {
                        Spacer()
                        RedXButton {
                            if let updatedItem = viewModel.removeSubitem(from: subitem.id, at: index) {
                                self.viewModel.subitem = updatedItem
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
                .if(!viewModel.isEditing) {
                    $0.scaleEffect(index == viewModel.hoveredIndex ? 1.3 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: index == viewModel.hoveredIndex)
                        .onTapGesture {
                            viewModel.action(item)
                        }
                        .contextMenu {
                            Button("Edit") {
                                viewModel.isEditing = true
                                NotificationCenter.default.post(
                                    name: .openShortcuts,
                                    object: nil,
                                    userInfo: nil
                                )
                            }
                        }
                        .onHover { hovering in
                            viewModel.hoveredIndex = hovering ? index : (viewModel.hoveredIndex == index ? nil : viewModel.hoveredIndex)
//                            showPopup = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                viewModel.submenuDegrees = angle.degrees - 92
                                viewModel.showPopup = true
                                viewModel.subitem = item
                            }
                        }
                }
                .if(viewModel.isEditing) {
                    $0.onHover { hovering in
                        viewModel.showPopup = true
                        viewModel.submenuDegrees = angle.degrees - 92
                        viewModel.subitem = item
                    }
                }
                .shadow(color: .black.opacity(0.6), radius: 4.0)
            if viewModel.isEditing {
                VStack {
                    HStack {
                        Spacer()
                        RedXButton {
                            viewModel.subitem = viewModel.remove(at: index)
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
                .cornerRadius(cornerRadius / 4)
                .frame(width: frame.width, height: frame.height)
        } else if object.type == .shortcut {
            if let data = object.imageData, let image = NSImage(data: data) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .cornerRadius(cornerRadius / 4)
                    .frame(width: frame.width, height: frame.height)
            }
            if object.showTitleOnIcon ?? true {
                Text(object.title)
                    .font(.system(size: 12))
                    .multilineTextAlignment(.center)
                    .padding(.all, 3)
                    .outlinedText(strokeColor: .black.opacity(0.3))
            }
        } else if object.type == .webpage {
            if let data = object.imageData, let image = NSImage(data: data) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .cornerRadius(cornerRadius / 4)
                    .frame(width: frame.width, height: frame.height)
                    .clipShape(
                        RoundedRectangle(cornerRadius: cornerRadius / 4)
                    )
                if object.showTitleOnIcon ?? true {
                    Text(object.title)
                        .font(.system(size: 12))
                        .multilineTextAlignment(.center)
                        .padding(.all, 3)
                        .outlinedText(strokeColor: .black.opacity(0.3))
                }
            } else if let path = object.browser?.icon {
                Image(path)
                    .resizable()
                    .frame(width: frame.width, height: frame.height)
                    .cornerRadius(cornerRadius / 4)
                if object.showTitleOnIcon ?? true {
                    Text(object.title)
                        .font(.system(size: 12))
                        .multilineTextAlignment(.center)
                        .padding(.all, 3)
                        .outlinedText(strokeColor: .black.opacity(0.3))
                }
            }
        } else if object.type == .utility {
            if let data = object.imageData, let image = NSImage(data: data) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .cornerRadius(cornerRadius / 4)
                    .frame(width: frame.width, height: frame.height)
            }
            if !object.title.isEmpty {
                if object.showTitleOnIcon ?? true {
                    Text(object.title)
                        .font(.system(size: 11))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(maxWidth: 80)
                        .outlinedText(strokeColor: .black.opacity(0.3))
                }
            }
        } else if object.type == .html {
            if let data = object.imageData, let image = NSImage(data: data) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .cornerRadius(cornerRadius / 4)
                    .frame(width: frame.width, height: frame.height)
            }
            if !object.title.isEmpty {
                if object.showTitleOnIcon ?? true {
                    Text(object.title)
                        .font(.system(size: 11))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(maxWidth: 80)
                        .outlinedText(strokeColor: .black.opacity(0.3))
                }
            }
        }
    }
}

struct CircularPageDotsView: View {
    var pageCount: Int
    var currentPage: Int
    var radius: CGFloat = 45
    var action: (Int) -> Void

    var body: some View {
        ZStack {
            ForEach(0..<pageCount, id: \.self) { index in
                let angle = Angle(degrees: Double(index) / Double(pageCount) * 360.0 - 90)
                let x = cos(angle.radians) * radius
                let y = sin(angle.radians) * radius

                Circle()
                    .fill(index == currentPage ? Color.white : Color.gray.opacity(0.6))
                    .frame(width: index == currentPage ? 14 : 10,
                           height: index == currentPage ? 14 : 10)
                    .position(x: radius + x, y: radius + y)
                    .animation(.interpolatingSpring(stiffness: 300, damping: 20), value: currentPage)
                    .onTapGesture {
                        action(index)
                    }
            }
        }
        .frame(width: radius * 2, height: radius * 2)
    }
}
