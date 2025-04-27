//
//  MacroRecorderView.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 27/04/2025.
//

import SwiftUI

class MacroUtilityViewModel: ObservableObject {
    var id: String?
    @Published var title: String = ""
    @Published var iconData: Data?
    @Published var selectedIcon: NSImage? = NSImage(named: "terminal")
    @Published var scriptCode: String = ""
    @Published var path: String = ""
    @Published var showTitleOnIcon: Bool = true
    
    func clear() {
        id = nil
        iconData = nil
        title = ""
        scriptCode = ""
        path = ""
        showTitleOnIcon = true
    }
}

struct MacroRecorderView: View {
    @ObservedObject var viewModel: MacroUtilityViewModel
    @StateObject private var recorder = KeyRecorder()
    var closeAction: () -> Void
    weak var delegate: UtilitiesWindowDelegate?
    let item: ShortcutObject?
    var currentPage: Int?
    
    init(item: ShortcutObject? = nil, delegate: UtilitiesWindowDelegate?, closeAction: @escaping () -> Void) {
        self.viewModel = MacroUtilityViewModel()
        self.item = item
        self.delegate = delegate
        self.closeAction = closeAction
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
        VStack(alignment: .center, spacing: 20) {
            Text("Macro Recorder")
                .font(.largeTitle)
                .padding()

            ScrollView(.horizontal) {
                HStack {
                    ForEach(recorder.recordedKeys) { record in
                        Text(record.key)
                            .padding(8)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
            .frame(height: 60)

            HStack(spacing: 20) {
                VStack {
                    Button(action: recorder.startRecording) {
                        Text("Start Recording")
                            .frame(width: 150)
                    }
                    .disabled(recorder.isRecording)

                    Button(action: recorder.stopRecording) {
                        Text("Stop Recording")
                            .frame(width: 150)
                    }
                    .disabled(!recorder.isRecording)
                }
            }
            .padding()
            
            HStack {
                IconPickerView(viewModel: .init(selectedImage: viewModel.selectedIcon) { image in
                    viewModel.selectedIcon = image
                }, userSelectedIcon: $viewModel.selectedIcon, title: viewModel.showTitleOnIcon
                               ? .constant(recorder.recordedKeys.map { $0.key }.joined())
                               : .constant(""))
                .padding(.leading, 60.0)
                
                BlueButton(title: "Cancel", font: .callout, padding: 12.0, backgroundColor: .gray) {
                    viewModel.clear()
                    closeAction()
                }
                .disabled(recorder.isRecording)
                .padding(.trailing, 6.0)
                BlueButton(title: "Save", font: .callout, padding: 12.0) {
                    viewModel.scriptCode = recorder.recordedKeys.map { $0.key }.joined(separator: ",")
                    delegate?.saveUtility(with:
                        .init(
                            type: .utility,
                            page: currentPage ?? 1,
                            path: viewModel.path,
                            id: viewModel.id ?? UUID().uuidString,
                            title: recorder.recordedKeys.map { $0.key }.joined(),
                            imageData: viewModel.selectedIcon?.toData,
                            scriptCode: viewModel.scriptCode,
                            utilityType: .macro,
                            showTitleOnIcon: viewModel.showTitleOnIcon,
                            category: "Macros"
                        )
                    )
                    viewModel.clear()
                    closeAction()
                }
                .disabled(recorder.isRecording)
            }
            .padding(.trailing, 6.0)

            Spacer()
        }
        .onAppear {
            if let script = item?.scriptCode {
                recorder.recordedKeys = script.split(separator: ",").map { .init(key: $0.base) }
            }
        }
    }
    
    func activateApp(named appName: String) {
        let apps = NSRunningApplication.runningApplications(withBundleIdentifier: appName)
        apps.first?.activate(options: [.activateAllWindows])
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
    
    func getBundleIdentifier(forAppAtPath appPath: String) -> String? {
        let appBundle = Bundle(path: appPath)
        return appBundle?.bundleIdentifier
    }
}
