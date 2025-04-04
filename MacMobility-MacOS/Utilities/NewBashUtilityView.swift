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
    @Published var selectedIcon: NSImage? = NSImage(named: "terminal")
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
            VStack(alignment: .leading) {
                Text("Bash Script Tool")
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(Color.white)
                    .padding(.bottom, 4)
                Text("Write bash script that can be triggered remotely.")
                    .foregroundStyle(Color.gray)
                    .lineLimit(2)
                    .font(.system(size: 12))
                    .padding(.bottom, 12)
            }
            Text("Script label")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.white)
                .padding(.bottom, 4)
            Text("Add a label that will be present on an icon and as the description on a list.")
                .foregroundStyle(Color.gray)
                .lineLimit(2)
                .font(.system(size: 12))
                .padding(.bottom, 12)
            TextField("", text: $viewModel.title)
            TextEditor(text: $viewModel.scriptCode)
                .frame(height: 160)
                .padding(.bottom, 12)
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
                        scriptCode: viewModel.scriptCode,
                        utilityType: .commandline
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
        .padding()
    }
}
