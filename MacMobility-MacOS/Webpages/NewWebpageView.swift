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
    
    func clear() {
        id = nil
        title = ""
        link = ""
        faviconLink = ""
    }
}

struct NewWebpageView: View {
    @ObservedObject var viewModel = NewWebpageViewModel()
    @State private var browser = Browsers.chrome
    weak var delegate: WebpagesWindowDelegate?
    
    init(item: ShortcutObject? = nil, delegate: WebpagesWindowDelegate?) {
        self.delegate = delegate
        if let item {
            self._browser = .init(initialValue: item.browser ?? .safari)
            viewModel.title = item.title
            viewModel.link = item.path ?? ""
            viewModel.id = item.id
            viewModel.faviconLink = item.faviconLink ?? ""
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
            Picker("Browser", selection: $browser) {
                Text("Chrome").tag(Browsers.chrome)
                Text("Safari").tag(Browsers.safari)
            }
            .pickerStyle(.menu)
            .padding()
            Button {
                delegate?.saveWebpage(with:
                    .init(type: .webpage, path: viewModel.link, id: viewModel.id ?? UUID().uuidString, title: viewModel.title, faviconLink: viewModel.faviconLink, browser: browser)
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
