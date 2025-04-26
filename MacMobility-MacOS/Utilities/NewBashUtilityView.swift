//
//  NewBashUtilityView.swift
//  MacMobility-MacOS
//
//  Created by CoderBlocks on 19/03/2025.
//

import SwiftUI

class NewBashUtilityViewModel: ObservableObject {
    var id: String?
    @Published var title: String = ""
    @Published var category: String = ""
    @Published var iconData: Data?
    @Published var selectedIcon: NSImage? = NSImage(named: "terminal")
    @Published var scriptCode: String = ""
    @Published var showTitleOnIcon: Bool = true
    
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
    @ObservedObject var viewModel = NewBashUtilityViewModel()
    var closeAction: () -> Void
    weak var delegate: UtilitiesWindowDelegate?
    var currentPage: Int?
    let backgroundColor = Color(.sRGB, red: 0.1, green: 0.1, blue: 0.1, opacity: 0.7)
    
    init(item: ShortcutObject? = nil, delegate: UtilitiesWindowDelegate?, closeAction: @escaping () -> Void) {
        self.delegate = delegate
        self.closeAction = closeAction
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
                RoundedTextField(placeholder: "", text: $viewModel.category)
            }
            .padding(.bottom, 6.0)
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
        .onAppear {
            for window in NSApplication.shared.windows {
                window.appearance = NSAppearance(named: .darkAqua)
            }
        }
        .padding()
    }
}

// --

import CodeEditor

struct Automation: Identifiable {
    let id = UUID()
    var name: String
    var script: String
}

class NewAutomationUtilityViewModel: ObservableObject {
    var id: String?
    @Published var title: String = ""
    @Published var category: String = ""
    @Published var iconData: Data?
    @Published var selectedIcon: NSImage? = NSImage(named: "automation")
    @Published var automationCode: String = ""
    @Published var showTitleOnIcon: Bool = true
    
    func clear() {
        id = nil
        iconData = nil
        title = ""
        category = ""
        automationCode = ""
        showTitleOnIcon = true
    }
    
    func loadAutomationFromFile() -> Automation? {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.plainText]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.title = "Choose an Automation Script"

        if panel.runModal() == .OK, let url = panel.url {
            do {
                let scriptContent = try String(contentsOf: url)
                let name = url.deletingPathExtension().lastPathComponent
                return Automation(name: name, script: scriptContent)
            } catch {
                print("Failed to read script file: \(error)")
            }
        }
        return nil
    }
}

struct NewAutomationUtilityView: View {
    @ObservedObject var viewModel = NewAutomationUtilityViewModel()
    var closeAction: () -> Void
    weak var delegate: UtilitiesWindowDelegate?
    var currentPage: Int?
    let backgroundColor = Color(.sRGB, red: 0.1, green: 0.1, blue: 0.1, opacity: 0.7)
    
    init(item: ShortcutObject? = nil, delegate: UtilitiesWindowDelegate?, closeAction: @escaping () -> Void) {
        self.delegate = delegate
        self.closeAction = closeAction
        if let item {
            currentPage = item.page
            viewModel.title = item.title
            viewModel.id = item.id
            viewModel.automationCode = item.scriptCode ?? ""
            viewModel.showTitleOnIcon = item.showTitleOnIcon ?? true
            viewModel.category = item.category ?? ""
            if let data = item.imageData {
                viewModel.selectedIcon = NSImage(data: data)
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .center) {
            Text("Automation Tool")
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
            
            BlueButton(title: "Load Automation from File", font: .callout, padding: 8.0, backgroundColor: .gray) {
                if let newAutomation = viewModel.loadAutomationFromFile() {
                    viewModel.automationCode = newAutomation.script
                }
            }
            .padding(.leading, 60.0)
            .padding(.bottom, 6.0)
            HStack(alignment: .top) {
                Text("Code")
                    .font(.system(size: 14, weight: .regular))
                
                CodeEditor(
                    source: $viewModel.automationCode,
                    language: .applescript,
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
                RoundedTextField(placeholder: "", text: $viewModel.category)
            }
            .padding(.bottom, 6.0)
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
                                scriptCode: viewModel.automationCode,
                                utilityType: .automation,
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
        .onAppear {
            for window in NSApplication.shared.windows {
                window.appearance = NSAppearance(named: .darkAqua)
            }
        }
        .padding()
    }
}
