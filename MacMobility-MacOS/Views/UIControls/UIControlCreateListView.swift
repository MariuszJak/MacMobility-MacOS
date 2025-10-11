//
//  UIControlCreateListView.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 23/08/2025.
//

import Foundation
import SwiftUI

struct UIControlCreateItem: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let type: UIControlType
}

enum UIControlType {
    case slider
    case knob
    
    var iconName: String {
        switch self {
        case .slider:
            return "slider-icon"
        case .knob:
            return "knob-icon"
        }
    }
    
    var size: CGSize {
        switch self {
        case .slider:
            return CGSize(width: 3, height: 1)
        case .knob:
            return CGSize(width: 2, height: 2)
        }
    }
    
    var path: String {
        switch self {
        case .slider:
            return "control:horizontal-slider"
        case .knob:
            return "control:rotary-knob"
        }
    }
    
    static func typeFromPath(_ path: String?) -> UIControlType? {
        guard let path else { return nil }
        if path == UIControlType.knob.path {
            return .knob
        } else if path == UIControlType.slider.path {
            return .slider
        } else {
            return nil
        }
    }
}

struct UIControlCreateListView: View {
    let types: [UIControlCreateItem] = [
        .init(
            id: UUID(),
            title: "Slider",
            description: "Create Slider UI Control",
            type: .slider
        ),
        .init(
            id: UUID(),
            title: "Knob",
            description: "Create Knob UI Control",
            type: .knob
        )
    ]
    
    let createAction: (UIControlType) -> Void
    
    var body: some View {
        VStack {
            HStack {
                Text("Select control type")
                    .font(.system(size: 17.0, weight: .bold))
                    .foregroundStyle(Color.white)
                    .padding([.horizontal, .top], 16)
                Spacer()
            }
            Divider()
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 240))], spacing: 6) {
                    ForEach(types) { control in
                        VStack(alignment: .leading) {
                            VStack(alignment: .leading) {
                                HStack(alignment: .top) {
                                    Image(control.type.iconName)
                                        .resizable()
                                        .frame(width: 64, height: 64)
                                        .padding(.trailing, 2.0)
                                    VStack(alignment: .leading) {
                                        Text(control.title)
                                            .lineLimit(1)
                                            .font(.system(size: 16, weight: .bold))
                                            .padding(.bottom, 4)
                                        Text(control.description)
                                            .font(.system(size: 12, weight: .regular))
                                            .foregroundStyle(Color.gray)
                                            .padding(.bottom, 8)
                                    }
                                }
                                Divider()
                                HStack {
                                    Spacer()
                                    Image(systemName: "plus.circle.fill")
                                        .resizable()
                                        .frame(width: 16, height: 16)
                                        .onTapGesture {
                                            createAction(control.type)
                                        }
                                    
                                }
                            }
                            .padding(.all, 10)
                        }
                        .padding(.all, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.gray.opacity(0.1))
                        )
                    }
                    ComingMoreView()
                }
                .padding(.horizontal)
            }
            .padding(.all, 16.0)
        }
        .background(
            RoundedBackgroundView()
        )
        .padding()
    }
}

struct ComingMoreView: View {
    var cornerRadius: CGFloat = 20.0
    let backgroundColor = Color(.sRGB, red: 0.1, green: 0.1, blue: 0.1, opacity: 1)
    let accentColor = Color(.sRGB, red: 0.3, green: 0.3, blue: 0.3, opacity: 1)
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(backgroundColor)

            Text("Coming More Soon!")
                .font(.system(size: 16.0, weight: .bold))
                .foregroundStyle(Color.white)
        }
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(accentColor, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.4), radius: 4, x: 0, y: 2)
    }
}
