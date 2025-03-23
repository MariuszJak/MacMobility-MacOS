//
//  AddNewScreenView.swift
//  MacMobility-MacOS
//
//  Created by CoderBlocks on 06/03/2025.
//

import Foundation
import SwiftUI

struct AddNewScreenView: View {
    let addAction: () -> Void
    
    var body: some View {
        VStack {
            Text("Add new screen")
        }
        .frame(width: 280, height: 140)
        .background(
            RoundedRectangle(cornerRadius: 20.0)
                .fill(Color.black.opacity(0.2))
        )
        .onTapGesture {
            addAction()
        }
    }
}
