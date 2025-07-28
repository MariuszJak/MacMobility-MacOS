//
//  DependenciesInstallView.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 09/06/2025.
//

import SwiftUI

enum DependencyType: String, Codable {
    case text
    case tool
}

struct DependencyObject: Codable, Identifiable {
    var id: String
    var type: DependencyType
    var description: String
    var tool: String?
}

class DependenciesInstallViewModel: ObservableObject {
    var dependencies: [DependencyObject] = []
    @Published var userText: [String] = []
    var dependencyUpdate: ([String]) -> Void
    
    init(dependencies: [DependencyObject], dependencyUpdate: @escaping ([String]) -> Void) {
        self.dependencyUpdate = dependencyUpdate
        self.dependencies = dependencies
        self.dependencies.forEach { _ in
            userText.append("")
        }
    }
    
    func save() {
        dependencies.enumerated().forEach { (index, dependency) in
            self.userText[index] = "DEPENDENCY_\(dependency.id)&+$" + self.userText[index]
        }
        dependencyUpdate(userText)
    }
}

struct DependenciesInstallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: DependenciesInstallViewModel
    
    init(dependencies: [DependencyObject], dependencyUpdate: @escaping ([String]) -> Void) {
        self._viewModel = .init(wrappedValue: .init(dependencies: dependencies, dependencyUpdate: dependencyUpdate))
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Required dependencies")
            ScrollView {
                ForEach(Array(viewModel.dependencies.enumerated()), id: \.offset) { (index, dependency) in
                    switch dependency.type {
                    case .text:
                        VStack(alignment: .leading) {
                            if let attributed = makeAttributedString(from: dependency.description) {
                                Text(attributed)
                                    .padding()
                            } else {
                                Text(dependency.description)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 12.0)
                            }
                            RoundedTextField(placeholder: "", text: $viewModel.userText[index])
                        }
                        .padding()
                    case .tool:
                        VStack(alignment: .leading) {
                            if let attributed = makeAttributedString(from: dependency.description) {
                                Text(attributed)
                                    .padding()
                            } else {
                                Text(dependency.description)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            
            HStack {
                Button("Close") {
                    dismiss()
                }
                if viewModel.dependencies.contains(where: { $0.type == .text }) {
                    Button("Save") {
                        viewModel.save()
                        dismiss()
                    }
                }
                Spacer()
            }
            .padding()
        }
        .padding()
        .frame(width: 500, height: 400)
    }
    
    func makeAttributedString(from string: String) -> AttributedString? {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        var attributedString = AttributedString(string)

        let nsString = NSString(string: string)
        let range = NSRange(location: 0, length: nsString.length)

        detector?.enumerateMatches(in: string, options: [], range: range) { match, _, _ in
            guard
                let match = match,
                let url = match.url,
                let stringRange = Range(match.range, in: string),
                let attributedRange = Range(match.range, in: attributedString)
            else { return }

            attributedString[attributedRange].link = url
            attributedString[attributedRange].foregroundColor = .blue
            attributedString[attributedRange].underlineStyle = .single
        }

        return attributedString
    }
}
