//
//  CompanionAppView.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 23/08/2025.
//

import Foundation
import SwiftUI

import QRCode

struct CompanionAppView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("Get the Companion App")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Scan the QR code below to download the iOS / iPadOS companion app from the App Store.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            if let image = generateQRCode() {
                Text("Scan to connect")
                Image(nsImage: image)
                    .resizable()
                    .frame(width: 200, height: 200)
            }

            Text("Or search for “MobilityControl” on the App Store.")
                .font(.footnote)
                .foregroundColor(.gray)
        }
        .padding()
    }
    
    func generateQRCode() -> NSImage? {
        let doc = QRCode.Document(utf8String: "https://apps.apple.com/pl/app/mobilitycontrol/id6744455092",
                                  errorCorrection: .high)
        guard let generated = doc.cgImage(CGSize(width: 800, height: 800)) else { return nil }
        return NSImage(cgImage: generated, size: .init(width: 200, height: 200))
    }
}
