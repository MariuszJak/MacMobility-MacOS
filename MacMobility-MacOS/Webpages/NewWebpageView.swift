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
    
    init(item: WebpageItem? = nil, delegate: WebpagesWindowDelegate?) {
        self.delegate = delegate
        if let item {
            self._browser = .init(initialValue: item.browser)
            viewModel.title = item.webpageTitle
            viewModel.link = item.webpageLink
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
                delegate?.saveWebpage(with: .init(id: viewModel.id ?? UUID().uuidString,
                                                  webpageTitle: viewModel.title,
                                                  webpageLink: viewModel.link,
                                                  faviconLink: viewModel.faviconLink,
                                                  browser: browser))
                viewModel.clear()
                delegate?.close()
            } label: {
                Text("Save")
            }
        }
        .padding()
    }
}

struct AllWebpagesView: View {
    @ObservedObject var viewModel: WebpagesWindowViewModel
    
    enum Constants {
        static let imageSize = 46.0
        static let cornerRadius = 6.0
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false ) {
            VStack {
                ForEach(viewModel.webpages) { webpage in
                    VStack(spacing: 0.0) {
                        if let link = webpage.faviconLink, let url = URL(string: link) {
                            AsyncImage(url: url,
                                       content: { image in
                                image
                                    .resizable()
                                    .cornerRadius(Constants.cornerRadius)
                                    .frame(width: Constants.imageSize, height: Constants.imageSize)
                            }, placeholder: {
                                Image("Empty")
                                    .resizable()
                                    .cornerRadius(Constants.cornerRadius)
                                    .frame(width: Constants.imageSize, height: Constants.imageSize)
                            })
                            .cornerRadius(Constants.cornerRadius)
                            .frame(width: Constants.imageSize, height: Constants.imageSize)
                        }
                        Text(webpage.webpageTitle)
                            .font(.caption2)
                            .frame(maxWidth: 50.0)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 10.0)
                    .padding(.vertical, 8.0)
                    .onTapGesture {
                        openWebPage(for: webpage)
                    }
                }
            }
        }
        .clipped()
        .background(VisualEffect().ignoresSafeArea())
    }
    
    func openWebPage(for webpageItem: WebpageItem) {
        guard let url = NSURL(string: webpageItem.webpageLink) as? URL else {
            return
        }
        NSWorkspace.shared.open([url],
                                withAppBundleIdentifier: webpageItem.browser.bundleIdentifier,
                                options: NSWorkspace.LaunchOptions.default,
                                additionalEventParamDescriptor: nil,
                                launchIdentifiers: nil)
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
