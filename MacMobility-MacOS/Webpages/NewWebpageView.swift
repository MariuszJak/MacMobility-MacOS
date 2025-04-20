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
    @Published var browser = Browsers.chrome
    @Published var showTitleOnIcon: Bool = true
    
    func clear() {
        id = nil
        iconData = nil
        title = ""
        link = ""
        faviconLink = ""
        browser = .chrome
        showTitleOnIcon = true
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
            IconPickerView(viewModel: .init(selectedImage: viewModel.selectedIcon) { image in
                viewModel.selectedIcon = image
            })
            Divider()
                .padding(.top, 8)
            Button {
                delegate?.saveWebpage(with:
                    .init(
                        type: .webpage,
                        page: currentPage ?? 1,
                        path: viewModel.link,
                        id: viewModel.id ?? UUID().uuidString,
                        title: viewModel.title,
                        faviconLink: viewModel.faviconLink,
                        browser: viewModel.browser,
                        imageData: viewModel.selectedIcon?.toData,
                        showTitleOnIcon: viewModel.showTitleOnIcon,
                        additions: nil
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

extension NSImage {
    var toData: Data? {
        guard let tiffData = self.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        
        return bitmap.representation(using: .png, properties: [:])
    }
}

struct VisualEffect: NSViewRepresentable {
    func updateNSView(_ nsView: NSView, context: Context) {}
    
    func makeNSView(context: Self.Context) -> NSView {
        let visualEffect = NSVisualEffectView()
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active
        visualEffect.material = .popover
        return visualEffect
    }
}

import SwiftUI
import AppKit

class IconPickerViewModel: ObservableObject {
    @Published var selectedImage: NSImage?
    var completion: (NSImage) -> Void
    
    init(selectedImage: NSImage?, completion: @escaping (NSImage) -> Void) {
        self.selectedImage = selectedImage
        self.completion = completion
    }
    
    func pickImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        
        if panel.runModal() == .OK, let url = panel.url {
            if let image = NSImage(contentsOf: url) {
                DispatchQueue.main.async {
                    self.selectedImage = image
                    self.completion(image)
                }
            }
        }
    }
}

struct IconPickerView: View {
    @StateObject private var viewModel: IconPickerViewModel
    @Binding var title: String
    
    init(viewModel: IconPickerViewModel, title: Binding<String> = .constant("")) {
        self._viewModel = .init(wrappedValue: viewModel)
        self._title = title
    }
    
    var body: some View {
        HStack {
            ZStack {
                if let image = viewModel.selectedImage {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    Text("No Icon Selected")
                        .frame(width: 100, height: 100)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                if !title.isEmpty {
                    Text(title)
                        .font(.system(size: 16))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(maxWidth: 100)
                        .stroke(color: .black)
                }
            }
            
            Button("Select Icon") {
                viewModel.pickImage()
            }
        }
        .onAppear {
            for window in NSApplication.shared.windows {
                window.appearance = NSAppearance(named: .darkAqua)
            }
        }
    }
}
