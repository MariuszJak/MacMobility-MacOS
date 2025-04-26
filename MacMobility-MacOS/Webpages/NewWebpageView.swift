//
//  NewWebpageView.swift
//  MacMobility-MacOS
//
//  Created by CoderBlocks on 14/03/2024.
//

import SwiftUI

class NewWebpageViewModel: ObservableObject {
    var id: String?
    @Published var title: String = ""
    @Published var link: String = ""
    @Published var faviconLink: String = ""
    @Published var iconData: Data?
    @Published var selectedIcon: NSImage?
    var savedIcon: NSImage?
    @Published var browser = Browsers.chrome
    @Published var showTitleOnIcon: Bool = true
    @Published var userSelectedIcon: NSImage?
    
    func clear() {
        id = nil
        iconData = nil
        title = ""
        link = ""
        faviconLink = ""
        browser = .chrome
        showTitleOnIcon = true
    }
    
    func fullLink() -> String {
        if link.contains("https://") {
            return link
        }
        return "https://\(link)"
    }
}

struct NewWebpageView: View {
    @ObservedObject var viewModel = NewWebpageViewModel()
    private var currentPage: Int?
    weak var delegate: WebpagesWindowDelegate?
    
    init(item: ShortcutObject? = nil, delegate: WebpagesWindowDelegate?) {
        self.delegate = delegate
        if let item {
            viewModel.browser = item.browser ?? .chrome
            viewModel.title = item.title
            viewModel.link = item.path ?? ""
            viewModel.id = item.id
            viewModel.faviconLink = item.faviconLink ?? ""
            viewModel.showTitleOnIcon = item.showTitleOnIcon ?? true
            currentPage = item.page
            if let data = item.imageData {
                viewModel.selectedIcon = NSImage(data: data)
                viewModel.userSelectedIcon = NSImage(data: data)
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .center) {
            Text("Add Link")
                .font(.system(size: 18.0, weight: .bold))
        }
        VStack(alignment: .leading) {
            HStack {
                Text("Title")
                    .font(.system(size: 14, weight: .regular))
                    .padding(.trailing, 20.0)
                RoundedTextField(placeholder: "", text: $viewModel.title)
            }
            .padding(.bottom, 6.0)
            .frame(maxWidth: .infinity)
            HStack {
                Text("Link")
                    .font(.system(size: 14, weight: .regular))
                    .padding(.trailing, 20.0)
                    .padding(.bottom, 16.0)
                VStack {
                    RoundedTextField(placeholder: "", text: $viewModel.link)
                        .padding(.bottom, 4.0)
                    Text("Start typing url, and icon will be automatically downloaded. If it fails, use direct url or select icon from disc.")
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.gray)
                        .padding(.leading, 20.0)
                }
            }
            .padding(.bottom, 6.0)
            .frame(maxWidth: .infinity)
            HStack {
                Text("Image")
                    .font(.system(size: 14, weight: .regular))
                    .padding(.trailing, 8.0)
                VStack(alignment: .leading) {
                    RoundedTextField(placeholder: "https://example.com/icon.png", text: $viewModel.faviconLink)
                        .padding(.bottom, 4.0)
                    Text("You can add any image URL here. Image will be cached after download.")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.gray)
                        .padding(.leading, 20.0)
                }
            }
            .padding(.bottom, 6.0)
            .frame(maxWidth: .infinity)
            Picker("Browser", selection: $viewModel.browser) {
                Text("Chrome").tag(Browsers.chrome)
                Text("Safari").tag(Browsers.safari)
            }
            .pickerStyle(.menu)
            .frame(width: 200.0)
            .padding(.bottom, 12.0)
            .padding(.leading, 70.0)
            
            IconPickerView(viewModel: .init(
                selectedImage: viewModel.selectedIcon ?? viewModel.savedIcon,
                shouldAutofetchImage: viewModel.userSelectedIcon == nil,
                searchText: viewModel.link,
                completion: { image in
                    viewModel.savedIcon = image
                }), userSelectedIcon: $viewModel.userSelectedIcon,
                           favicon: $viewModel.faviconLink
            )
            .padding(.bottom, 12.0)
            .padding(.leading, 70.0)
            HStack(alignment: .center) {
                Toggle("", isOn: $viewModel.showTitleOnIcon)
                    .padding(.trailing, 6.0)
                    .toggleStyle(.switch)
                Text("Show title on icon")
                    .font(.system(size: 14.0))
            }
            .padding(.leading, 65.0)
            
            HStack {
                Spacer()
                BlueButton(title: "Cancel", font: .callout, padding: 12.0, backgroundColor: .gray) {
                    viewModel.clear()
                    delegate?.close()
                }
                .padding(.trailing, 6.0)
                BlueButton(title: "Save", font: .callout, padding: 12.0) {
                    delegate?.saveWebpage(with:
                        .init(
                            type: .webpage,
                            page: currentPage ?? 1,
                            path: viewModel.fullLink(),
                            id: viewModel.id ?? UUID().uuidString,
                            title: viewModel.title,
                            faviconLink: viewModel.faviconLink,
                            browser: viewModel.browser,
                            imageData: viewModel.userSelectedIcon?.toData ?? viewModel.savedIcon?.toData,
                            showTitleOnIcon: viewModel.showTitleOnIcon
                        )
                    )
                    viewModel.clear()
                    delegate?.close()
                }
            }
            .padding(.trailing, 28.0)
        }
        .onAppear {
            for window in NSApplication.shared.windows {
                window.appearance = NSAppearance(named: .darkAqua)
            }
        }
        .padding()
    }
}

struct RoundedTextField: View {
    let backgroundColor = Color(.sRGB, red: 0.1, green: 0.1, blue: 0.1, opacity: 0.7)
    @Binding private var text: String
    private let placeholder: String
    
    init(placeholder: String, text: Binding<String>) {
        self.placeholder = placeholder
        self._text = text
    }

    var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(PlainTextFieldStyle())
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
                    .stroke(Color.gray.opacity(0.4), lineWidth: 1)
            )
            .padding(.horizontal)
    }
}
