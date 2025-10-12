//
//  AnalyticsConsentView.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 12/10/2025.
//

import SwiftUI

struct AnalyticsConsentPrompt: View {
    var onAgree: () -> Void
    var onDisagree: () -> Void
    @Binding var isPresented: Bool
    
    @State private var showDetails = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 50, weight: .semibold))
                        .foregroundStyle(.white)
                    
                    Text("Analytics & Improvements")
                        .font(.title3.weight(.semibold))
                        .multilineTextAlignment(.center)
                    
                    Text("We’d like to collect anonymous analytics data to improve app performance and user experience. No personal data is ever shared.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                VStack(spacing: 10) {
                    Button("Allow Analytics") {
                        isPresented = false
                        onAgree()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    Button("No, Thanks") {
                        isPresented = false
                        onDisagree()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
                
                if showDetails {
                    Text("You can change this anytime in Settings → Privacy.")
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.background)
                    .shadow(color: .black.opacity(0.25), radius: 20, y: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(.separator.opacity(0.3))
            )
            .onAppear {
                showDetails = true
            }
        }
    }
}
