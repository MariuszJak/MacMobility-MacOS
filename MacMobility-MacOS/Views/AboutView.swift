//
//  AboutView.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 13/04/2025.
//

import Foundation
import SwiftUI

struct AboutView: View {
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    public var body: some View {
        HStack {
            VStack {
                Spacer()
                Image(.logo)
                    .resizable()
                    .frame(width: 128, height: 128)
                    .cornerRadius(20)
                Spacer()
            }
            .padding()
            VStack(alignment: .leading) {
                Spacer()
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
                Spacer()
            }
            .padding()
        }
        .onAppear {
            for window in NSApplication.shared.windows {
                window.appearance = NSAppearance(named: .darkAqua)
            }
        }
        .padding(.horizontal, 21.0)
    }
}
