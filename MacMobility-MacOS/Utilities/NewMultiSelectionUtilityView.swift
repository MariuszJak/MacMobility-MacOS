//
//  NewMultiSelectionUtilityView.swift
//  MacMobility-MacOS
//
//  Created by CoderBlocks on 20/03/2025.
//

import SwiftUI

struct NewMultiSelectionUtilityView: View {
    @ObservedObject var viewModel: NewMultiSelectionUtilityViewModel
    var closeAction: () -> Void
    weak var delegate: UtilitiesWindowDelegate?
    private var currentPage: Int?
    let cornerRadius = 17.0
    
    init(item: ShortcutObject? = nil, delegate: UtilitiesWindowDelegate?, closeAction: @escaping () -> Void) {
        self.delegate = delegate
        self.closeAction = closeAction
        self.viewModel = .init(allObjects: delegate?.allObjects() ?? [])
        if let item {
            currentPage = item.page
            viewModel.title = item.title
            viewModel.id = item.id
            currentPage = item.page
            if let objects = item.objects {
                viewModel.configuredShortcuts = objects
            }
            if let data = item.imageData {
                viewModel.selectedIcon = NSImage(data: data)
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                Text("Multiselection Tool")
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(Color.white)
                    .padding(.bottom, 4)
                Text("Drag & Drop apps, shortcuts, webpages and utilities")
                    .foregroundStyle(Color.gray)
                    .lineLimit(2)
                    .font(.system(size: 12))
                    .padding(.bottom, 12)
            }
            .padding(.horizontal, 10)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 6) {
                ForEach(0..<6) { index in
                    VStack {
                        ZStack {
                            itemViews(for: index)
                                .frame(width: 70, height: 70)
                                .clipped()
                            if let id = viewModel.objectAt(index: index)?.id {
                                VStack {
                                    HStack {
                                        Spacer()
                                        RedXButton {
                                            viewModel.removeShortcut(id: id)
                                        }
                                    }
                                    Spacer()
                                }
                            }
                        }
                    }
                    .frame(width: 70, height: 70)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color.black.opacity(0.4))
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
                                    viewModel.addConfiguredShortcut(object:
                                            .init(
                                                type: object.type,
                                                page: 1,
                                                index: index,
                                                path: object.path,
                                                id: object.id,
                                                title: object.title,
                                                color: object.color,
                                                faviconLink: object.faviconLink,
                                                browser: object.browser,
                                                imageData: object.imageData,
                                                scriptCode: object.scriptCode,
                                                utilityType: object.utilityType,
                                                objects: object.objects
                                            )
                                    )
                                }
                            }
                        }
                        return true
                    }
                }
            }
            .padding(.bottom, 12)
            VStack(alignment: .leading) {
                Text("Multiselection label")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.white)
                    .padding(.bottom, 4)
                Text("Add a label that will be present on an icon and as the description on a list.")
                    .foregroundStyle(Color.gray)
                    .lineLimit(2)
                    .font(.system(size: 12))
                    .padding(.bottom, 12)
                TextField("", text: $viewModel.title)
                IconPickerView(viewModel: .init(selectedImage: viewModel.selectedIcon) { image in
                    viewModel.selectedIcon = image
                }, title: $viewModel.title)
                Divider()
                    .padding(.top, 8)
                Button {
                    delegate?.saveUtility(with:
                            .init(
                                type: .utility,
                                page: currentPage ?? 1,
                                id: viewModel.id ?? UUID().uuidString,
                                title: viewModel.title,
                                imageData: viewModel.selectedIcon?.toData,
                                utilityType: .multiselection,
                                objects: viewModel.configuredShortcuts
                            )
                    )
                    viewModel.clear()
                    closeAction()
                } label: {
                    Text("Save")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.green)
                }
            }
            .padding(.horizontal, 10)
        }
        .onAppear {
            for window in NSApplication.shared.windows {
                window.appearance = NSAppearance(named: .darkAqua)
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private func itemViews(for index: Int) -> some View {
        if let object = viewModel.objectAt(index: index) {
            if let path = object.path, object.type == .app {
                Image(nsImage: NSWorkspace.shared.icon(forFile: path))
                    .resizable()
                    .scaledToFill()
                    .frame(width: 85, height: 85)
            } else if object.type == .shortcut {
                if let data = object.imageData, let image = NSImage(data: data) {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                        .cornerRadius(cornerRadius)
                        .frame(width: 70, height: 70)
                }
                Text(object.title)
                    .font(.system(size: 12))
                    .multilineTextAlignment(.center)
                    .padding(.all, 3)
                    .stroke(color: Color.black)
            } else if object.type == .webpage {
                if let data = object.imageData, let image = NSImage(data: data) {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .cornerRadius(cornerRadius)
                        .frame(width: 70, height: 70)
                        .clipShape(
                            RoundedRectangle(cornerRadius: cornerRadius)
                        )
                    Text(object.title)
                        .font(.system(size: 12))
                        .multilineTextAlignment(.center)
                        .padding(.all, 3)
                        .stroke(color: Color.black)
                } else if let path = object.browser?.icon {
                    Image(path)
                        .resizable()
                        .frame(width: 80, height: 80)
                        .cornerRadius(cornerRadius)
                    Text(object.title)
                        .font(.system(size: 12))
                        .multilineTextAlignment(.center)
                        .padding(.all, 3)
                        .stroke(color: Color.black)
                }
            } else if object.type == .utility {
                if let data = object.imageData, let image = NSImage(data: data) {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                        .cornerRadius(cornerRadius)
                        .frame(width: 70, height: 70)
                }
                if !object.title.isEmpty {
                    Text(object.title)
                        .font(.system(size: 11))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(maxWidth: 80)
                        .stroke(color: Color.black)
                }
            }
        }
    }
}
