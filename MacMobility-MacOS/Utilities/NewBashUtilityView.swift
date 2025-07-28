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
    @Published var title: String = ""
    @Published var category: String = "Other"
    @Published var iconData: Data?
    @Published var selectedIcon: NSImage? = NSImage(named: "terminal")
    @Published var scriptCode: String = ""
    @Published var showTitleOnIcon: Bool = true
    @Published var categories: [String] = []
    
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
    }
}

struct NewBashUtilityView: View {
    @ObservedObject var viewModel: NewBashUtilityViewModel
    var closeAction: () -> Void
    weak var delegate: UtilitiesWindowDelegate?
    var currentPage: Int?
    let backgroundColor = Color(.sRGB, red: 0.1, green: 0.1, blue: 0.1, opacity: 0.7)
    
    init(categories: [String], item: ShortcutObject? = nil, delegate: UtilitiesWindowDelegate?, closeAction: @escaping () -> Void) {
        self.delegate = delegate
        self.closeAction = closeAction
        self.viewModel = NewBashUtilityViewModel(categories: categories)
        if let item {
            currentPage = item.page
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
                            scriptCode: viewModel.scriptCode,
                            utilityType: .commandline,
                            showTitleOnIcon: viewModel.showTitleOnIcon,
                            category: viewModel.category
                        )
                    )
                    viewModel.clear()
                    closeAction()
                }
            }
            .padding(.trailing, 6.0)
        }
        .frame(minWidth: 500.0)
        .padding()
    }
}

// ---

class RaycastViewModel: ObservableObject, JSONLoadable {
    var id: String?
    @Published var title: String = ""
    @Published var iconData: Data?
    @Published var selectedIcon: NSImage? = NSImage(named: "raycastIcon")
    @Published var scriptCode: String = ""
    @Published var showTitleOnIcon: Bool = true
    
    func clear() {
        id = nil
        iconData = nil
        title = ""
        scriptCode = ""
        showTitleOnIcon = true
    }
}

struct RaycastUtilityView: View {
    @ObservedObject var viewModel: RaycastViewModel
    var closeAction: () -> Void
    weak var delegate: UtilitiesWindowDelegate?
    var currentPage: Int?
    let backgroundColor = Color(.sRGB, red: 0.1, green: 0.1, blue: 0.1, opacity: 0.7)
    
    init(item: ShortcutObject? = nil, delegate: UtilitiesWindowDelegate?, closeAction: @escaping () -> Void) {
        self.delegate = delegate
        self.closeAction = closeAction
        self.viewModel = RaycastViewModel()
        if let item {
            currentPage = item.page
            viewModel.title = item.title
            viewModel.id = item.id
            viewModel.scriptCode = item.scriptCode ?? ""
            viewModel.showTitleOnIcon = item.showTitleOnIcon ?? true
            if let data = item.imageData {
                viewModel.selectedIcon = NSImage(data: data)
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .center) {
            Text("Raycast")
                .font(.system(size: 18.0, weight: .bold))
        }
        VStack(alignment: .leading) {
            HStack {
                Text("Title")
                    .font(.system(size: 14, weight: .regular))
                    .padding(.trailing, 28.0)
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
                Text("Deeplink")
                    .font(.system(size: 14, weight: .regular))
                
                CodeEditor(
                    source: $viewModel.scriptCode,
                    language: .http,
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
            .padding(.bottom, 8.0)
            HStack {
                IconPickerView(viewModel: .init(selectedImage: viewModel.selectedIcon) { image in
                    viewModel.selectedIcon = image
                }, userSelectedIcon: $viewModel.selectedIcon, title: viewModel.showTitleOnIcon ? $viewModel.title : .constant(""))
                .padding(.leading, 80.0)
                
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
                            color: .raycast,
                            imageData: viewModel.selectedIcon?.toData,
                            scriptCode: viewModel.scriptCode,
                            utilityType: .commandline,
                            showTitleOnIcon: viewModel.showTitleOnIcon,
                            category: "Raycast"
                        )
                    )
                    viewModel.clear()
                    closeAction()
                }
            }
            .padding(.trailing, 6.0)
        }
        .frame(minWidth: 500.0)
        .padding()
    }
}

// --

class HTMLUtilityViewModel: ObservableObject, JSONLoadable {
    var id: String?
    @Published var title: String = ""
    @Published var category: String = "Other"
    @Published var iconData: Data?
    @Published var selectedIcon: NSImage? = NSImage(named: "terminal")
    @Published var scriptCode: String = ""
    @Published var showTitleOnIcon: Bool = true
    @Published var categories: [String] = []
    
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
    }
}

struct HTMLUtilityView: View {
    @ObservedObject var viewModel: HTMLUtilityViewModel
    var closeAction: () -> Void
    weak var delegate: UtilitiesWindowDelegate?
    var currentPage: Int?
    let backgroundColor = Color(.sRGB, red: 0.1, green: 0.1, blue: 0.1, opacity: 0.7)
    
    init(categories: [String], item: ShortcutObject? = nil, delegate: UtilitiesWindowDelegate?, closeAction: @escaping () -> Void) {
        self.delegate = delegate
        self.closeAction = closeAction
        self.viewModel = HTMLUtilityViewModel(categories: categories)
        if let item {
            currentPage = item.page
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
            Text("HTML")
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
                    language: .javascript,
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
                    closeAction()
                }
                .padding(.trailing, 6.0)
                BlueButton(title: "Save", font: .callout, padding: 12.0) {
                    delegate?.saveUtility(with:
                        .init(
                            type: .html,
                            page: currentPage ?? 1,
                            id: viewModel.id ?? UUID().uuidString,
                            title: viewModel.title,
                            imageData: viewModel.selectedIcon?.toData,
                            scriptCode: viewModel.scriptCode,
                            utilityType: .html,
                            showTitleOnIcon: viewModel.showTitleOnIcon,
                            category: viewModel.category
                        )
                    )
                    viewModel.clear()
                    closeAction()
                }
            }
            .padding(.trailing, 6.0)
        }
        .frame(minWidth: 500.0)
        .padding()
    }
}
