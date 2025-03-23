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
    
    func validate() {
        guard !key.isEmpty else { return }
        let validation = applicenseManager.validate(key: key)
        licenseValidationStep = validation ? .valid : .invalid
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
            
            Text("Activate your license to unlock the full features of the app. Enter your license key below to proceed. If you don’t have a key, you can get one at www.coderblocks.eu. Need help? Contact us at kontakt@coderblocks.eu.")
                .font(.system(size: 12))
                .foregroundStyle(Color.gray)
                .padding(.bottom, 10)
            Text("Enter your license key:")
                .font(.system(size: 14))
                .padding(.bottom, 8)
            TextField("", text: $viewModel.key)
                .padding(.bottom, 10)
            Button {
                viewModel.validate()
            } label: {
                Text(viewModel.licenseValidationStep.title)
                    .foregroundStyle(viewModel.licenseValidationStep.color)
            }

        }
        .padding()
    }
}
