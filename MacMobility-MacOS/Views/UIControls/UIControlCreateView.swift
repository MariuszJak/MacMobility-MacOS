//
//  UIControlCreateView.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 23/08/2025.
//

import Foundation
import SwiftUI
import CodeEditor

struct UIControlPayload {
    let type: UIControlType
    let initialCode: String?
    let code: String
}

class UIControlCreateViewViewModel: ObservableObject, JSONLoadable {
    var id: String?
    @Published var uiControlType: UIControlType = .slider
    @Published var type: ShortcutType = .control
    @Published var size: CGSize = .init(width: 1, height: 1)
    @Published var path: String = ""
    @Published var title: String = ""
    @Published var category: String = "MacOS"
    @Published var iconData: Data?
    @Published var selectedIcon: NSImage? = NSImage(named: "terminal")
    @Published var scriptCode: String = ""
    @Published var initialScriptCode: String = ""
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

struct UIControlCreateView: View {
    @ObservedObject var viewModel: UIControlCreateViewViewModel
    var connectionManager: ConnectionManager
    var closeAction: (ShortcutObject?) -> Void
    weak var delegate: UtilitiesWindowDelegate?
    var currentPage: Int?
    let backgroundColor = Color(.sRGB, red: 0.1, green: 0.1, blue: 0.1, opacity: 0.7)
    var testAction: (UIControlPayload) -> Void
    
    init(
        type: UIControlType,
        connectionManager: ConnectionManager,
        categories: [String],
        item: ShortcutObject? = nil,
        delegate: UtilitiesWindowDelegate?,
        closeAction: @escaping (ShortcutObject?) -> Void,
        testAction: @escaping (UIControlPayload) -> Void
    ) {
        self.connectionManager = connectionManager
        self.delegate = delegate
        self.closeAction = closeAction
        self.testAction = testAction
        self.viewModel = UIControlCreateViewViewModel(categories: categories)
        self.viewModel.uiControlType = type
        self.viewModel.selectedIcon = NSImage(named: type.iconName)
        self.viewModel.size = item?.size ?? type.size
        self.viewModel.path = item?.path ?? type.path
        if let item {
            currentPage = item.page
            viewModel.type = item.type
            viewModel.title = item.title
            viewModel.id = item.id
            viewModel.scriptCode = item.scriptCode ?? ""
            viewModel.showTitleOnIcon = item.showTitleOnIcon ?? true
            viewModel.category = item.category ?? ""
            if let data = item.imageData {
                viewModel.selectedIcon = NSImage(data: data)
            }
            if let initialScriptCode = item.color, !initialScriptCode.isEmpty {
                viewModel.initialScriptCode = initialScriptCode
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .center) {
            Text("UI Control")
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
            .padding(.leading, 80.0)
            .frame(maxWidth: .infinity)
            HStack(alignment: .top) {
                Text("Initial Value Code")
                    .font(.system(size: 14, weight: .regular))
                
                CodeEditor(
                    source: $viewModel.initialScriptCode,
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
            .frame(height: 100.0)
            HStack(alignment: .top) {
                Text("Component Code")
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
                Spacer()
                BlueButton(
                    title: "Test UI Control",
                    font: .callout,
                    padding: 8.0,
                    cornerRadius: 6.0,
                    leadingImage: "app.connected.to.app.below.fill"
                ) {
                    testAction(.init(
                        type: viewModel.uiControlType,
                        initialCode: viewModel.initialScriptCode,
                        code: viewModel.scriptCode)
                    )
                }
                .padding(.all, 6.0)
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
                    closeAction(nil)
                }
                .padding(.trailing, 6.0)
                BlueButton(title: "Save", font: .callout, padding: 12.0) {
                    let object: ShortcutObject = .init(
                        type: viewModel.type,
                        page: currentPage ?? 1,
                        size: viewModel.size,
                        path: viewModel.path,
                        id: viewModel.id ?? UUID().uuidString,
                        title: viewModel.title,
                        color: viewModel.initialScriptCode,
                        imageData: viewModel.selectedIcon?.toData,
                        scriptCode: viewModel.scriptCode,
                        utilityType: .commandline,
                        showTitleOnIcon: viewModel.showTitleOnIcon,
                        category: viewModel.category
                    )
                    delegate?.saveUtility(with: object)
                    viewModel.clear()
                    closeAction(object)
                }
            }
            .padding(.trailing, 6.0)
        }
        .frame(minWidth: 500.0)
        .padding()
    }
}
