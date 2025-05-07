//
//  ConverterView.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 06/05/2025.
//

import SwiftUI

class ConverterViewModel: ObservableObject {
    let formatOptions = [
        "heic", "jpeg", "jpg", "png", "pdf", "tiff", "bmp", "gif"
    ]
    
    var id: String?
    @Published var title: String = ""
    @Published var iconData: Data?
    @Published var selectedIcon: NSImage? = NSImage(named: "convertIcon")
    @Published var scriptCode: String = ""
    @Published var showTitleOnIcon: Bool = true
    @Published var inputFormat: String = "heic"
    @Published var outputFormat: String = "jpeg"
    
    func clear() {
        id = nil
        iconData = nil
        title = ""
        scriptCode = ""
        showTitleOnIcon = true
    }
}

struct ConverterView: View {
    @ObservedObject var viewModel: ConverterViewModel
    @State private var automationName: String = ""
    var currentPage: Int?
    weak var delegate: UtilitiesWindowDelegate?
    let item: ShortcutObject?
    var closeAction: () -> Void
    
    init(item: ShortcutObject? = nil, delegate: UtilitiesWindowDelegate? = nil, closeAction: @escaping () -> Void) {
        self.viewModel = ConverterViewModel()
        self.item = item
        self.delegate = delegate
        self.closeAction = closeAction
        if let item {
            currentPage = item.page
            viewModel.title = item.title
            viewModel.id = item.id
            viewModel.scriptCode = item.scriptCode ?? ""
            viewModel.showTitleOnIcon = item.showTitleOnIcon ?? true
            let input = item.scriptCode?.split(separator: ",")[1]
            let output = item.scriptCode?.split(separator: ",")[2]
            self.viewModel.inputFormat = String(input ?? "heic")
            self.viewModel.outputFormat = String(output ?? "jpeg")
            if let data = item.imageData {
                viewModel.selectedIcon = NSImage(data: data)
            }
        } else {
            viewModel.scriptCode = "FILE_CONVERTER,\(viewModel.inputFormat),\(viewModel.outputFormat)"
            viewModel.title = "\(viewModel.inputFormat.uppercased()) to \(viewModel.outputFormat.uppercased())"
        }
    }

    var body: some View {
        VStack(alignment: .center) {
            Text("Create File Conversion Automation")
                .font(.system(size: 18.0, weight: .bold))
        }
        .padding(.bottom, 21.0)
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Picker("From: ", selection: $viewModel.inputFormat) {
                        ForEach(viewModel.formatOptions.filter { $0 != viewModel.outputFormat }, id: \.self) {
                            Text($0.uppercased())
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: viewModel.inputFormat) { oldValue, newValue in
                        viewModel.scriptCode = "FILE_CONVERTER,\(newValue),\(viewModel.outputFormat)"
                        viewModel.title = "\(newValue.uppercased()) to \(viewModel.outputFormat.uppercased())"
                    }
                }
                
                Button {
                    let tmp = viewModel.inputFormat
                    viewModel.inputFormat = viewModel.outputFormat
                    viewModel.outputFormat = tmp
                } label: {
                    Image(systemName: "arrow.2.squarepath")
                        .rotationEffect(.degrees(90))
                }
                .padding(.horizontal)

                VStack(alignment: .leading) {
                    Picker("To: ", selection: $viewModel.outputFormat) {
                        ForEach(viewModel.formatOptions.filter { $0 != viewModel.inputFormat }, id: \.self) {
                            Text($0.uppercased())
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: viewModel.outputFormat) { oldValue, newValue in
                        viewModel.scriptCode = "FILE_CONVERTER,\(viewModel.inputFormat),\(newValue)"
                        viewModel.title = "\(viewModel.inputFormat.uppercased()) to \(newValue.uppercased())"
                    }
                }
            }
            .padding(.bottom, 21.0)
            HStack {
                IconPickerView(
                    viewModel: .init(selectedImage: viewModel.selectedIcon) { image in
                        viewModel.selectedIcon = image
                    },
                    userSelectedIcon: $viewModel.selectedIcon,
                    title: viewModel.showTitleOnIcon ? $viewModel.title : .constant(""),
                    canSelectImage: false)
                
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
                            color: .convert,
                            imageData: viewModel.selectedIcon?.toData,
                            scriptCode: viewModel.scriptCode,
                            utilityType: .commandline,
                            showTitleOnIcon: viewModel.showTitleOnIcon,
                            category: "Converter"
                        )
                    )
                    viewModel.clear()
                    closeAction()
                }
            }
            .padding(.trailing, 6.0)
            Spacer()
        }
        .padding()
    }
}

extension String {
    static var convert: String {
        return "convert"
    }
}
