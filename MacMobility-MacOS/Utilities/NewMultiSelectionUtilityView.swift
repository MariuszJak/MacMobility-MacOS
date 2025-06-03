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
            viewModel.showTitleOnIcon = item.showTitleOnIcon ?? true
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
        VStack(alignment: .center) {
            Text("Multiselection Tool")
                .font(.system(size: 18.0, weight: .bold))
        }
        VStack(alignment: .leading) {
            HStack {
                Text("Title")
                    .font(.system(size: 14, weight: .regular))
                    .padding(.trailing, 4.0)
                RoundedTextField(placeholder: "", text: $viewModel.title)
                HStack(alignment: .center) {
                    Toggle("", isOn: $viewModel.showTitleOnIcon)
                        .padding(.trailing, 6.0)
                        .toggleStyle(.switch)
                    Text("Show title on icon")
                        .font(.system(size: 14.0))
                }
            }
            .padding(.bottom, 6.0)
            .frame(maxWidth: .infinity)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 16) {
                ForEach(0..<12) { index in
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
                        PlusButtonView()
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
                                                indexes: neighboringIndexes(for: index, size: object.size ?? .init(width: 1, height: 1)),
                                                size: object.size ?? .init(width: 1, height: 1),
                                                path: object.path,
                                                id: object.id,
                                                title: object.title,
                                                color: object.color,
                                                faviconLink: object.faviconLink,
                                                browser: object.browser,
                                                imageData: object.imageData,
                                                scriptCode: object.scriptCode,
                                                utilityType: object.utilityType,
                                                objects: object.objects,
                                                showTitleOnIcon: object.showTitleOnIcon ?? true,
                                                category: object.category
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
            
            HStack {
                IconPickerView(viewModel: .init(selectedImage: viewModel.selectedIcon) { image in
                    viewModel.selectedIcon = image
                }, userSelectedIcon: $viewModel.selectedIcon, title: viewModel.showTitleOnIcon ? $viewModel.title : .constant(""))
                
                Spacer()
                BlueButton(title: "Cancel", font: .callout, padding: 12.0, backgroundColor: .gray) {
                    viewModel.clear()
                    closeAction()
                }
                .padding(.trailing, 6.0)
                BlueButton(title: "Save", font: .callout, padding: 12.0) {
                    delegate?.saveUtility(with:
                            .init(
                                type: .utility,
                                page: currentPage ?? 1,
                                id: viewModel.id ?? UUID().uuidString,
                                title: viewModel.title,
                                imageData: viewModel.selectedIcon?.toData,
                                utilityType: .multiselection,
                                objects: viewModel.configuredShortcuts,
                                showTitleOnIcon: viewModel.showTitleOnIcon,
                                category: "Multiselection"
                            )
                    )
                    viewModel.clear()
                    closeAction()
                }
            }
            .padding(.trailing, 6.0)
        }
        .onAppear {
            for window in NSApplication.shared.windows {
                window.appearance = NSAppearance(named: .darkAqua)
            }
        }
        .padding()
    }
    
    func neighboringIndexes(for index: Int, size: CGSize, inGridWithColumns columns: Int = 7, rows: Int = 3) -> [Int]? {
        let totalSquares = columns * rows
        let objectWidth = Int(size.width)
        let objectHeight = Int(size.height)

        let startRow = index / columns
        let startCol = index % columns

        // Check if the object would go out of bounds
        if startCol + objectWidth > columns || startRow + objectHeight > rows {
            return nil
        }

        var result: [Int] = []

        for dy in 0..<objectHeight {
            for dx in 0..<objectWidth {
                let newRow = startRow + dy
                let newCol = startCol + dx
                let newIndex = newRow * columns + newCol

                // Additional safety check
                if newIndex < totalSquares {
                    result.append(newIndex)
                } else {
                    return nil
                }
            }
        }

        return result
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
                        .frame(width: 70, height: 70)
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
                        .frame(width: 80, height: 80)
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
                        .frame(width: 70, height: 70)
                }
                if !object.title.isEmpty && object.showTitleOnIcon ?? true {
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
