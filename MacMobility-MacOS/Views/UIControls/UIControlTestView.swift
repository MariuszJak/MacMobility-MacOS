//
//  UIControlTestView.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 26/08/2025.
//

import Foundation
import SwiftUI

struct UIControlTestView: View, ScriptExecutable {
    let payload: UIControlPayload
    let connectionManager: ConnectionManager
    
    var body: some View {
        VStack {
            switch payload.type {
            case .slider:
                VolumeContainerView(initialScript: execute(script: payload.initialCode ?? "")) { value in
                    handleCode(payload.code, value: value)
                }
            case .knob:
                RotaryKnob(title: "", initialScript: execute(script: payload.initialCode ?? "")) { value in
                    handleCode(payload.code, value: value)
                }
            }
        }
        .frame(width: payload.type.size.width * 80, height: payload.type.size.height * 80)
    }
    
    func handleCode(_ code: String, value: Int) {
        let scriptCode = code
        let updatedScript = String(format: scriptCode, value)
        connectionManager.runInlineBashScript(script: updatedScript)
    }
}
