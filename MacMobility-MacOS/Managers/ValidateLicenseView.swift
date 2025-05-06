//
//  ValidateLicenseView.swift
//  MacMobility-MacOS
//
//  Created by CoderBlocks on 23/03/2025.
//

import Foundation
import SwiftUI

public class ValidateLicenseViewModel: ObservableObject {
    public enum LicenseValidationStep {
        case trial
        case valid
        case invalid
        
        var title: String {
            switch self {
            case .trial:
                return "Validate"
            case .valid:
                return "License confirmed!"
            case .invalid:
                return "License is invalid, try again"
            }
        }
        
        var color: Color {
            switch self {
            case .trial:
                return .white
            case .valid:
                return .green
            case .invalid:
                return .red
            }
        }
    }
    
    @Published var key: String = ""
    @Published var exampleKey: String = ""
    @Published var licenseValidationStep: LicenseValidationStep = .trial
    @LazyInject var applicenseManager: AppLicenseManager
    
    func validate() async {
        guard !key.isEmpty else { return }
        await applicenseManager.validate(key: key.replacingOccurrences(of: " ", with: "")) { [weak self] validated in
            self?.licenseValidationStep = validated ? .valid : .invalid
        }
    }
}

public struct ValidateLicenseView: View {
    @ObservedObject var viewModel: ValidateLicenseViewModel
    
    init(viewModel: ValidateLicenseViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(alignment: .leading) {
            Text("License Activation")
                .font(.system(size: 21, weight: .bold))
                .padding(.bottom, 10)
            
            Text("Activate your license to continue using the app beyond the 14-day trial. Enter your license key below to proceed. Need help? Contact us at kontakt@coderblocks.eu. We’re happy to offer a full refund within 14 days of purchase, provided the license key has not been activated.")
                .font(.system(size: 12))
                .foregroundStyle(Color.gray)
                .padding(.bottom, 6)
            Text("Enter your license key:")
                .font(.system(size: 14))
                .padding(.bottom, 8)
            TextField("", text: $viewModel.key)
                .lineLimit(1)
                .padding(.bottom, 10)
            Button {
                Task {
                    await viewModel.validate()
                }
            } label: {
                Text(viewModel.licenseValidationStep.title)
                    .foregroundStyle(viewModel.licenseValidationStep.color)
            }
        }
        .onAppear {
            for window in NSApplication.shared.windows {
                window.appearance = NSAppearance(named: .darkAqua)
            }
        }
        .padding()
    }
}
