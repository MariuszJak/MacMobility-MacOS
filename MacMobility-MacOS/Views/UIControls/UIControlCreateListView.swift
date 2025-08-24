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
}

struct UIControlCreateListView: View {
    let types: [UIControlCreateItem] = [
        .init(
            id: UUID(),
            title: "Volume Slider",
            description: "Create Slider UI Control",
            type: .slider
        ),
        .init(
            id: UUID(),
            title: "Volume Knob",
            description: "Create Knob UI Control",
            type: .knob
        )
    ]
    
    let createAction: (UIControlType) -> Void
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 400))], spacing: 6) {
                ForEach(types) { control in
                    HStack(alignment: .top) {
                        Image(control.type.iconName)
                            .resizable()
                            .frame(width: 80.0, height: 80.0)
                            .padding(.trailing, 20.0)
                        VStack(alignment: .leading) {
                            Text(control.title)
                                .font(.title2)
                                .padding(.bottom, 6.0)
                            Text(control.description)
                                .font(.caption)
                                .foregroundStyle(Color.gray)
                                .padding(.bottom, 8.0)
                            
                        }
                        Spacer()
                        Button("Create") {
                            createAction(control.type)
                        }
                        .padding()
                    }
                    .padding(.all, 18.0)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.gray.opacity(0.1))
                    )
                }
            }
            .padding()
        }
        .background(
            RoundedBackgroundView()
        )
        .padding(.all, 16.0)
    }
}
