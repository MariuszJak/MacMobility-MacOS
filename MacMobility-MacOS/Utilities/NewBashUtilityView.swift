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
    @Published var iconData: Data?
    @Published var selectedIcon: NSImage?
    @Published var scriptCode: String = ""
    
    func clear() {
        id = nil
        iconData = nil
        title = ""
        scriptCode = ""
    }
}

struct NewBashUtilityView: View {
    @ObservedObject var viewModel = NewBashUtilityViewModel()
    var closeAction: () -> Void
    weak var delegate: UtilitiesWindowDelegate?
    var currentPage: Int?
    
    init(item: ShortcutObject? = nil, delegate: UtilitiesWindowDelegate?, closeAction: @escaping () -> Void) {
        self.delegate = delegate
        self.closeAction = closeAction
        if let item {
            currentPage = item.page
            viewModel.title = item.title
            viewModel.id = item.id
            viewModel.scriptCode = item.scriptCode ?? ""
            if let data = item.imageData {
                viewModel.selectedIcon = NSImage(data: data)
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Utility title:")
            TextField("", text: $viewModel.title)
                .padding()
            TextEditor(text: $viewModel.scriptCode)
                .frame(height: 150)
                .padding()
                .border(Color.gray, width: 1)
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
                        scriptCode: viewModel.scriptCode,
                        utilityType: .commandline
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
