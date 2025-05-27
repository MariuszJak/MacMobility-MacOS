//
//  ValidateLicenseView.swift
//  MacMobility-MacOS
//
//  Created by CoderBlocks on 23/03/2025.
//

import Foundation
import SwiftUI
import Combine

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
    @Published var email: String = ""
    @Published var exampleKey: String = ""
    @Published var licenseValidationStep: LicenseValidationStep = .trial
    @Published var isCheckDisabled: Bool = true
    @LazyInject var applicenseManager: AppLicenseManager
    private var regex = NSRegularExpression.Regex.email
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        bind()
    }
    
    func validate() async {
        guard !key.isEmpty, !email.isEmpty, regex.expression.matches(email) else { return }
        let clearKey = key.replacingOccurrences(of: " ", with: "")
        await applicenseManager.validate(key: clearKey, email: email) { [weak self] validated in
            self?.licenseValidationStep = validated ? .valid : .invalid
        }
    }
    
    func bind() {
        Publishers.CombineLatest($email, $key)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (email, password) in
                guard let self else { return }
                let isCheckDisabled = !(self.regex.expression.matches(email) && !key.isEmpty)
                self.isCheckDisabled = isCheckDisabled
            }
            .store(in: &cancellables)
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
            
            Text("Activate your license to continue using the app beyond the 14-day trial. Enter your license key and email below to proceed. Need help? Contact us at kontakt@coderblocks.eu. We’re happy to offer a partial refund within 14 days of purchase, provided the license key has not been activated.")
                .font(.system(size: 12))
                .foregroundStyle(Color.gray)
                .padding(.bottom, 6)
            Text("Enter your email:")
                .font(.system(size: 14))
                .padding(.bottom, 8)
            TextField("", text: $viewModel.email)
                .lineLimit(1)
                .padding(.bottom, 10)
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
                    .foregroundStyle(
                        viewModel.isCheckDisabled
                        ? .gray
                        : viewModel.licenseValidationStep.color
                    )
            }
            .disabled(viewModel.isCheckDisabled)
        }
        .onAppear {
            for window in NSApplication.shared.windows {
                window.appearance = NSAppearance(named: .darkAqua)
            }
        }
        .padding()
    }
}

public extension NSRegularExpression {
    enum Regex {
        case email
        
        public var expression: NSRegularExpression {
            switch self {
            case .email:
                return .init("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$")
            }
        }
    }
    
    convenience init(_ pattern: String) {
        do {
            try self.init(pattern: pattern)
        } catch {
            preconditionFailure("Illegal regular expression: \(pattern)")
        }
    }
    
    func matches(_ string: String) -> Bool {
        let range = NSRange(location: 0, length: string.utf16.count)
        return firstMatch(in: string, options: [], range: range) != nil
    }
}
