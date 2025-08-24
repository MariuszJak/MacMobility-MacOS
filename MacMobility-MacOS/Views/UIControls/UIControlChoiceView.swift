//
//  UIControlChoiceView.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 23/08/2025.
//

import Foundation
import SwiftUI

struct UIControlChoiceView: View {
    @State private var selectedMode: String = "prepared"
    private let action: (SetupMode) -> Void
    
    let options: [SetupMode] = [
        SetupMode(title: "Premade UI Controls",
                  description: "Get started quickly with few premade UI Controls",
                  imageName: "sparkles",
                  type: .advanced),
        
        SetupMode(title: "Create Yourself",
                  description: "Choose UI Control type and customize to your liking",
                  imageName: "square.dashed",
                  type: .basic)
    ]
    
    init(_ setupMode: SetupMode?, action: @escaping (SetupMode) -> Void) {
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 32) {
            Text("What would you like to do?")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Choose a UI control type.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            HStack(spacing: 24) {
                ForEach(options.indices, id: \.self) { index in
                    let mode = options[index]
                    let isSelected = (selectedMode == "prepared" && index == 0) || (selectedMode == "blank" && index == 1)
                    
                    VStack(spacing: 12) {
                        Image(systemName: mode.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundColor(isSelected ? .blue : .gray)

                        Text(mode.title)
                            .font(.headline)

                        Text(mode.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 3 : 1)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
                            )
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedMode = (index == 0) ? "prepared" : "blank"
                    }
                }
            }
            Button("Confirm") {
                let index = selectedMode == "prepared" ? 1 : 0
                action(options[index])
            }
        }
        .padding()
    }
}
