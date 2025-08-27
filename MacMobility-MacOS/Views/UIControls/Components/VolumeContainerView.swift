//
//  VolumeContainerView.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 26/08/2025.
//

import Foundation
import SwiftUI

struct VolumeContainerView: View {
    var completion: (Int) -> Void
    var iconSize = 24.0
    let initialValue: Double
    
    init(initialScript: String?, completion: @escaping (Int) -> Void, iconSize: Double = 24.0) {
        self.completion = completion
        self.iconSize = iconSize
        
        if let value = initialScript {
            let sanitizedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
            initialValue = (Double(sanitizedValue) ?? 50) / 100
        } else {
            initialValue = 0.5
        }
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.96, green: 0.96, blue: 0.96))
            HStack {
                BarView(initialValue: initialValue, completion: completion)
                    .padding(.horizontal, 16.0)
            }
        }
    }
}

struct BarView: View {
    @State private var progress: Double = 0.5
    @State private var previousValue: Double? = 0.5
    var completion: (Int) -> Void
    var throttler = Throttler<Int>()
    
    init(
        initialValue: Double,
        completion: @escaping (Int) -> Void
    ) {
        self.progress = initialValue
        self.completion = completion
        throttler.action = { value in
            completion(value)
        }
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            RoundedRectangle(cornerRadius: 20)
                .frame(height: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.init(hex: "FF6906"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.black.opacity(0.4))
                        )
                )
                .shadow(color: .black.opacity(0.05), radius: 4)

            GeometryReader { geometry in
                HStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(red: 0.96, green: 0.96, blue: 0.96))
                        .frame(width: geometry.size.width * progress)
                    Spacer(minLength: 0)
                }
                .frame(height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let newProgress = min(max(0, value.location.x / geometry.size.width), 1)
                            progress = newProgress
                            let significantDigits = getFirstTwoDecimalDigits(of: newProgress)
                            
                            if let prev = previousValue {
                                let previousDigits = getFirstTwoDecimalDigits(of: prev)
                                if previousDigits != significantDigits {
                                    let value = Double(round(100 * newProgress) / 100) * 100
                                    throttler.send(Int(value))
                                }
                            }
                            previousValue = newProgress
                        }
                )
            }
            .frame(height: 60)
        }
    }
    
    private func getFirstTwoDecimalDigits(of value: Double) -> (Int, Int) {
        let shifted = value * 100
        let intPart = Int(shifted)
        let first = intPart / 10
        let second = intPart % 10
        return (first, second)
    }
}
