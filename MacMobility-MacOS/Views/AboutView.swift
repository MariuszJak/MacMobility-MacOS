//
//  AboutView.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 13/04/2025.
//

import Foundation
import SwiftUI

struct AboutView: View {
    @State private var buttonTitle = "Copy license key"
    
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    var licenceKey: String {
        UserDefaults.standard.getUserDefaults(key: .licenseKey) ?? "-"
    }
    
    public var body: some View {
        VStack {
            VStack {
                Image(.logo)
                    .resizable()
                    .frame(width: 90, height: 90)
                    .cornerRadius(10)
            }
            .padding(.bottom, 18.0)
            VStack(alignment: .center) {
                Text("MacMobility")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.white)
                    .padding(.bottom, 6.0)
                HStack {
                    Text("Current version")
                        .foregroundStyle(Color.gray)
                    Text("\(appVersion)")
                        .foregroundStyle(Color.white)
                }
                .padding(.bottom, 18.0)
                HStack {
                    Text("Your license key:")
                        .foregroundStyle(Color.gray)
                    Text("\(licenceKey)")
                        .foregroundStyle(Color.white)
                        .textSelection(.enabled)
                    
                }
                .padding(.bottom, 6.0)
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(licenceKey, forType: .string)
                    buttonTitle = "Copied!"
                    
                    // Optional: Reset title after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        buttonTitle = "Copy license key"
                    }
                }) {
                    Text(buttonTitle)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.bottom, 18.0)
        }
        .onAppear {
            for window in NSApplication.shared.windows {
                window.appearance = NSAppearance(named: .darkAqua)
            }
        }
        .padding(.horizontal, 21.0)
    }
}
