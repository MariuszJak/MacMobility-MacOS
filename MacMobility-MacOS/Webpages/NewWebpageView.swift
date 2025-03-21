//
//  NewWebpageView.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 14/03/2024.
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
    
    func clear() {
        id = nil
        iconData = nil
        title = ""
        link = ""
        faviconLink = ""
        browser = .chrome
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
            currentPage = item.page
            if let data = item.imageData {
                viewModel.selectedIcon = NSImage(data: data)
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Webpage link title:")
            TextField("", text: $viewModel.title)
            Text("Link:")
            TextField("", text: $viewModel.link)
            Text("Favicon:")
            TextField("", text: $viewModel.faviconLink)
            Picker("Browser", selection: $viewModel.browser) {
                Text("Chrome").tag(Browsers.chrome)
                Text("Safari").tag(Browsers.safari)
            }
            .pickerStyle(.menu)
            .padding()
            IconPickerView(viewModel: .init(selectedImage: viewModel.selectedIcon) { image in
                viewModel.selectedIcon = image
            })
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
                        imageData: viewModel.selectedIcon?.toData
                    )
                )
                viewModel.clear()
                delegate?.close()
            } label: {
                Text("Save")
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
                        .font(.system(size: 12))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(maxWidth: 80)
                        .background(
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.black.opacity(0.8))
                        )
                        .padding(.top, 40)
                }
            }
            
            Button("Select Icon") {
                viewModel.pickImage()
            }
        }
        .padding()
    }
}
