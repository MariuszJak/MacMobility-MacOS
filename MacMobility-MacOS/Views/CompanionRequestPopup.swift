//
//  CompanionRequestPopup.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 23/08/2025.
//

import Foundation
import SwiftUI

struct CompanionRequestPopup: View {
    let deviceName: String
    let onAccept: () -> Void
    let onDeny: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Companion Device Detected")
                .font(.title2)
                .fontWeight(.bold)

            Text("“\(deviceName)” wants to connect to this Mac.")
                .multilineTextAlignment(.center)
                .font(.body)
                .foregroundColor(.secondary)

            HStack(spacing: 16) {
                Button("Deny") {
                    onDeny()
                }
                .keyboardShortcut(.cancelAction)
                .buttonStyle(.bordered)

                Button("Accept") {
                    onAccept()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(minWidth: 320)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.thinMaterial)
                .shadow(radius: 10)
        )
        .padding()
    }
}
