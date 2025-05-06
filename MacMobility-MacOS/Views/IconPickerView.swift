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
    private var imageSize: CGSize
    
    init(viewModel: IconPickerViewModel,
         userSelectedIcon: Binding<NSImage?> = .constant(nil),
         title: Binding<String> = .constant(""),
         favicon: Binding<String> = .constant(""),
         imageSize: CGSize = .init(width: 100.0, height: 100.0)) {
        self._viewModel = .init(wrappedValue: viewModel)
        self._title = title
        self._favicon = favicon
        self._userSelectedIcon = userSelectedIcon
        self.imageSize = imageSize
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
            
            Button("Select Icon") {
                viewModel.pickImage() { icon in
                    userSelectedIcon = icon
                }
            }
        }
        .onAppear {
            for window in NSApplication.shared.windows {
                window.appearance = NSAppearance(named: .darkAqua)
            }
        }
    }
}
