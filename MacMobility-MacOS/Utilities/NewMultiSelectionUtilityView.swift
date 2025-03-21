//
//  NewMultiSelectionUtilityView.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 20/03/2025.
//

import SwiftUI

struct NewMultiSelectionUtilityView: View {
    @ObservedObject var viewModel: NewMultiSelectionUtilityViewModel
    var closeAction: () -> Void
    weak var delegate: UtilitiesWindowDelegate?
    private var currentPage: Int?
    
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
            Text("Multiselection title:")
            TextField("", text: $viewModel.title)
                .padding()
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 6) {
                    ForEach(0..<6) { index in
                        VStack {
                            if let object = viewModel.objectAt(index: index) {
                                if let path = object.path, object.type == .app {
                                    ZStack {
                                        Image(nsImage: NSWorkspace.shared.icon(forFile: path))
                                            .resizable()
                                            .frame(width: 80, height: 80)
                                            .cornerRadius(8.0)
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
                                } else if object.type == .webpage {
                                    ZStack {
                                        if let data = object.imageData, let image = NSImage(data: data) {
                                            Image(nsImage: image)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .cornerRadius(6.0)
                                                .frame(width: 70, height: 70)
                                        } else if let path = object.browser?.icon {
                                            Image(path)
                                                .resizable()
                                                .frame(width: 70, height: 70)
                                                .cornerRadius(20)
                                        }
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
                                } else if object.type == .utility {
                                    ZStack {
                                        if let data = object.imageData, let image = NSImage(data: data) {
                                            Image(nsImage: image)
                                                .resizable()
                                                .scaledToFill()
                                                .cornerRadius(6.0)
                                                .frame(width: 70, height: 70)
                                        }
                                        VStack {
                                            HStack {
                                                Spacer()
                                                RedXButton {
                                                    viewModel.removeShortcut(id: object.id)
                                                }
                                            }
                                            Spacer()
                                        }
                                        if !object.title.isEmpty {
                                            Text(object.title)
                                                .font(.system(size: 11))
                                                .multilineTextAlignment(.center)
                                                .lineLimit(2)
                                                .frame(maxWidth: 80)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 2)
                                                        .fill(Color.black.opacity(0.8))
                                                )
                                                .padding(.top, 20)
                                        }
                                    }
                                }
                            }
                        }
                        .frame(width: 70, height: 70)
                        .background(
                            RoundedRectangle(cornerRadius: 8.0)
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
                .padding([.horizontal, .top])
            }
            
            IconPickerView(viewModel: .init(selectedImage: viewModel.selectedIcon) { image in
                viewModel.selectedIcon = image
            }, title: $viewModel.title)
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
            }
        }
        .padding()
    }
}
