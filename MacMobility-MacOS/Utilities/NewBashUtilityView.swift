//
//  NewBashUtilityView.swift
//  MacMobility-MacOS
//
//  Created by CoderBlocks on 19/03/2025.
//

import SwiftUI
import CodeEditor

class NewBashUtilityViewModel: ObservableObject, JSONLoadable {
    var id: String?
    @Published var type: ShortcutType = .utility
    @Published var size: CGSize = .init(width: 1, height: 1)
    @Published var path: String = ""
    @Published var title: String = ""
    @Published var category: String = "Other"
    @Published var iconData: Data?
    @Published var selectedIcon: NSImage? = NSImage(named: "terminal")
    @Published var scriptCode: String = ""
    @Published var showTitleOnIcon: Bool = true
    @Published var categories: [String] = []
    @Published var sizes: [ItemSize] = ItemSize.onlyRectangleSizes
    
    var itemSize: ItemSize {
        size.toItemSize ?? .size1x1
    }
    
    init(categories: [String]) {
        self.categories = categories
    }
    
    func clear() {
        id = nil
        iconData = nil
        title = ""
        category = ""
        scriptCode = ""
        showTitleOnIcon = true
        sizes = ItemSize.onlyRectangleSizes
    }
}

struct NewBashUtilityView: View {
    @ObservedObject var viewModel: NewBashUtilityViewModel
    var closeAction: (ShortcutObject?) -> Void
    weak var delegate: UtilitiesWindowDelegate?
    var currentPage: Int?
    let backgroundColor = Color(.sRGB, red: 0.1, green: 0.1, blue: 0.1, opacity: 0.7)
    
    init(categories: [String], item: ShortcutObject? = nil, delegate: UtilitiesWindowDelegate?, closeAction: @escaping (ShortcutObject?) -> Void) {
        self.delegate = delegate
        self.closeAction = closeAction
        self.viewModel = NewBashUtilityViewModel(categories: categories)
        if let item {
            currentPage = item.page
            viewModel.size = item.size ?? .init(width: 1, height: 1)
            viewModel.path = item.path ?? ""
            viewModel.type = item.type
            viewModel.title = item.title
            viewModel.id = item.id
            viewModel.scriptCode = item.scriptCode ?? ""
            viewModel.showTitleOnIcon = item.showTitleOnIcon ?? true
            viewModel.category = item.category ?? ""
            if let data = item.imageData {
                viewModel.selectedIcon = NSImage(data: data)
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .center) {
            Text("Bash Script")
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
            
            HStack(alignment: .top) {
                Text("Code")
                    .font(.system(size: 14, weight: .regular))
                
                CodeEditor(
                    source: $viewModel.scriptCode,
                    language: .bash,
                    theme: .pojoaque,
                    fontSize: .constant(14.0),
                    flags: .defaultEditorFlags,
                    indentStyle: .system,
                    autoPairs: nil,
                    inset: nil,
                    allowsUndo: true
                )
                .cornerRadius(12.0)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(backgroundColor)
                        .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                )
                .padding(.leading, 16.0)
            }
            HStack {
                Text("Size")
                    .font(.system(size: 14, weight: .regular))
                    .padding(.trailing, 4.0)
                Picker("", selection: Binding(
                    get: {
                        viewModel.itemSize.description
                    },
                    set: { newValue in
                        let newSize: ItemSize = ItemSize(rawValue: "size\(newValue)") ?? .size1x1
                        viewModel.size = newSize.cgSize
                    }
                )) {
                    ForEach(viewModel.sizes, id: \.self) { size in
                        Text(size.description)
                            .tag(size.description)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(width: 200.0)
                Spacer()
            }
            .padding(.bottom, 6.0)
            .padding(.leading, 60.0)
            .frame(maxWidth: .infinity)
            HStack {
                Text("Category")
                    .font(.system(size: 14, weight: .regular))
                    .padding(.trailing, 4.0)
                Picker("", selection: Binding(
                    get: {
                        viewModel.categories.contains(viewModel.category) ? viewModel.category : "Other"
                    },
                    set: { newValue in
                        if viewModel.categories.contains(newValue) {
                            viewModel.category = newValue
                        } else {
                            viewModel.category = ""
                        }
                    }
                )) {
                    ForEach(viewModel.categories, id: \.self) { option in
                        Text(option)
                            .tag(option)
                    }
                    Text("Other")
                        .tag("Other")
                }
                .pickerStyle(MenuPickerStyle())
                RoundedTextField(placeholder: "", text: $viewModel.category)
            }
            .padding(.bottom, 6.0)
            .padding(.leading, 60.0)
            .frame(maxWidth: .infinity)
            HStack {
                IconPickerView(viewModel: .init(selectedImage: viewModel.selectedIcon) { image in
                    viewModel.selectedIcon = image
                }, userSelectedIcon: $viewModel.selectedIcon, title: viewModel.showTitleOnIcon ? $viewModel.title : .constant(""))
                .padding(.leading, 60.0)
                
                Spacer()
                BlueButton(title: "Cancel", font: .callout, padding: 12.0, backgroundColor: .gray) {
                    viewModel.clear()
                    closeAction(nil)
                }
                .padding(.trailing, 6.0)
                BlueButton(title: "Save", font: .callout, padding: 12.0) {
                    let item: ShortcutObject = .init(
                        type: viewModel.type,
                        page: currentPage ?? 1,
                        size: viewModel.size,
                        path: viewModel.path,
                        id: viewModel.id ?? UUID().uuidString,
                        title: viewModel.title,
                        imageData: viewModel.selectedIcon?.toData,
                        scriptCode: viewModel.scriptCode,
                        utilityType: .commandline,
                        showTitleOnIcon: viewModel.showTitleOnIcon,
                        category: viewModel.category
                    )
                    delegate?.saveUtility(with: item)
                    viewModel.clear()
                    closeAction(item)
                }
            }
            .padding(.trailing, 6.0)
        }
        .frame(minWidth: 500.0)
        .padding()
    }
}
