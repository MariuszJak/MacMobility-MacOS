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
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                Text("Websites Link")
                    .font(.system(size: 21, weight: .bold))
                    .padding(.bottom, 4)
                Text("Create a shortcut for a website link. Add url, title, icon or favicon to customise your shortcut.")
                    .foregroundStyle(Color.gray)
                    .lineLimit(2)
                    .font(.system(size: 12))
                    .padding(.bottom, 12)
            }
            Text("Webpage link title")
                .font(.system(size: 14, weight: .bold))
                .padding(.bottom, 4)
            TextField("", text: $viewModel.title)
                .padding(.bottom, 4)
            Toggle("Show title on icon", isOn: $viewModel.showTitleOnIcon)
                .padding(.bottom, 12)
            Text("Link")
                .font(.system(size: 14, weight: .bold))
                .padding(.bottom, 4)
            TextField("", text: $viewModel.link)
                .padding(.bottom, 8)
            Text("Favicon")
                .font(.system(size: 14, weight: .bold))
                .padding(.bottom, 4)
            TextField("", text: $viewModel.faviconLink)
                .padding(.bottom, 8)
            Picker("Browser", selection: $viewModel.browser) {
                Text("Chrome").tag(Browsers.chrome)
                Text("Safari").tag(Browsers.safari)
            }
            .pickerStyle(.menu)
            IconPickerView(viewModel: .init(
                selectedImage: viewModel.selectedIcon ?? viewModel.savedIcon,
                shouldAutofetchImage: viewModel.userSelectedIcon == nil,
                searchText: viewModel.link,
                completion: { image in
                    viewModel.savedIcon = image
                }), userSelectedIcon: $viewModel.userSelectedIcon
            )
            Divider()
                .padding(.top, 8)
            Button {
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
            } label: {
                Text("Save")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.green)
            }
        }
        .onAppear {
            for window in NSApplication.shared.windows {
                window.appearance = NSAppearance(named: .darkAqua)
            }
        }
        .padding()
    }
}
