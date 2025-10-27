//
//  UnnamedScriptInstallView.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 27/10/2025.
//

import Foundation
import SwiftUI

struct UnnamedScriptInstallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var script: AutomationScript
    private let closure: (AutomationScript) -> Void
    @State private var userText: String = ""
    
    init(script: AutomationScript, closure: @escaping (AutomationScript) -> Void) {
        self.script = script
        self.closure = closure
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Required dependencies")
            ScrollView {
                VStack(alignment: .leading) {
                    Text("Please enter script name:")
                        .padding()
                    RoundedTextField(placeholder: "", text: $userText)
                        .padding()
                }
                .onChange(of: userText) { oldValue, newValue in
                    script.id = UUID()
                    script.name = newValue
                }
            }
            
            HStack {
                Button("Close") {
                    dismiss()
                }
                Button("Save") {
                    closure(script)
                    dismiss()
                }
                Spacer()
            }
            .padding()
        }
        .padding()
        .frame(width: 500, height: 400)
    }
}
