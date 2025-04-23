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
    
    init(viewModel: IconPickerViewModel, userSelectedIcon: Binding<NSImage?> = .constant(nil), title: Binding<String> = .constant("")) {
        self._viewModel = .init(wrappedValue: viewModel)
        self._title = title
        self._userSelectedIcon = userSelectedIcon
    }
    
    var body: some View {
        HStack {
            ZStack {
                if let userSelectedIcon {
                    Image(nsImage: userSelectedIcon)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else if let image = viewModel.selectedImage {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {                    
                    PlusButtonView(size: .init(width: 100, height: 100))
                        .opacity(0.7)
                }
                if !viewModel.isFetchingIcon && !title.isEmpty {
                    Text(title)
                        .font(.system(size: 16))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(maxWidth: 100)
                        .stroke(color: .black)
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
