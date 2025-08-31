//
//  IconPickerView.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 21/04/2025.
//

import SwiftUI

struct IconPickerView: View {
    @ObservedObject private var viewModel: IconPickerViewModel
    @Binding var title: String
    @Binding private var userSelectedIcon: NSImage?
    @Binding private var favicon: String
    @State var iconPickerWindow: NSWindow?
    private var imageSize: CGSize
    private let canSelectImage: Bool
    
    init(
        viewModel: IconPickerViewModel,
        userSelectedIcon: Binding<NSImage?> = .constant(nil),
        title: Binding<String> = .constant(""),
        favicon: Binding<String> = .constant(""),
        imageSize: CGSize = .init(width: 100.0, height: 100.0),
        canSelectImage: Bool = true
    ) {
        self._viewModel = .init(wrappedValue: viewModel)
        self._title = title
        self._favicon = favicon
        self._userSelectedIcon = userSelectedIcon
        self.imageSize = imageSize
        self.canSelectImage = canSelectImage
    }
    
    var body: some View {
        HStack {
            ZStack {
                if let userSelectedIcon {
                    Image(nsImage: userSelectedIcon)
                        .resizable()
                        .scaledToFill()
                        .frame(width: imageSize.width, height: imageSize.height)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else if let image = viewModel.selectedImage {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: imageSize.width, height: imageSize.height)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else if !favicon.isEmpty, let url = URL(string: favicon) {
                    AsyncImage(url: url,
                               content: { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: imageSize.width, height: imageSize.height)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }, placeholder: {
                        Image("Empty")
                            .resizable()
                            .scaledToFill()
                            .frame(width: imageSize.width, height: imageSize.height)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    })
                } else {
                    PlusButtonView(size: imageSize)
                        .opacity(0.7)
                }
                if !viewModel.isFetchingIcon && !title.isEmpty {
                    Text(title)
                        .font(.system(size: 16))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(maxWidth: imageSize.width)
                        .outlinedText()
                }
                if viewModel.isFetchingIcon {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.7)
                }
            }
            if canSelectImage {
                VStack(alignment: .leading) {
                    Button("Browse Icons") {
                        openIconsPickerWindow()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    Button("Select Icon") {
                        viewModel.pickImage() { icon in
                            userSelectedIcon = icon
                        }
                    }
                }
            }
        }
    }
    
    func openIconsPickerWindow() {
        iconPickerWindow?.close()
        iconPickerWindow = nil
        if nil == iconPickerWindow {
            iconPickerWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 700, height: 500),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            iconPickerWindow?.center()
            iconPickerWindow?.setFrameAutosaveName("IconPickerWindow")
            iconPickerWindow?.isReleasedWhenClosed = false
            iconPickerWindow?.titlebarAppearsTransparent = true
            iconPickerWindow?.appearance = NSAppearance(named: .darkAqua)
            iconPickerWindow?.styleMask.insert(.fullSizeContentView)
            
            guard let visualEffect = NSVisualEffectView.createVisualAppearance(for: iconPickerWindow) else {
                return
            }
            iconPickerWindow?.contentView?.addSubview(visualEffect, positioned: .below, relativeTo: nil)
            let hv = NSHostingController(rootView: IconSelectorView(action: { name in
                iconPickerWindow?.close()
                userSelectedIcon = loadImage(named: name)
            }))
            iconPickerWindow?.contentView?.addSubview(hv.view)
            hv.view.frame = iconPickerWindow?.contentView?.bounds ?? .zero
            hv.view.autoresizingMask = [.width, .height]
            iconPickerWindow?.makeKeyAndOrderFront(nil)
            return
        }
        iconPickerWindow?.makeKeyAndOrderFront(nil)
    }
    
    private func loadImage(named name: String) -> NSImage? {
        if let fromAssets = NSImage(named: name) { return fromAssets }
        if let url = Bundle.main.url(forResource: name, withExtension: nil, subdirectory: "Icons") {
            return NSImage(contentsOf: url)
        }
        return nil
    }
}
