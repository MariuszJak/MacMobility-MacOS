//
//  InstallAutomationsView.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 29/04/2025.
//

import SwiftUI

struct InstallAutomationsView: View {
    let automationItem: AutomationItem
    let action: () -> Void
    
    var body: some View {
        VStack {
            HStack(alignment: .top) {
                VStack {
                    if let data = automationItem.imageData, let image = NSImage(data: data)  {
                        Image(nsImage: image)
                            .resizable()
                            .frame(width: 128, height: 128)
                            .cornerRadius(20)
                            .padding(.bottom, 21.0)
                        Button("Open") {
                            action()
                        }
                        .padding(.bottom, 28.0)
                    }
                }
                .padding(.trailing, 21.0)
                VStack(alignment: .leading) {
                    Text(automationItem.title)
                        .font(.system(size: 21, weight: .bold))
                        .padding(.bottom, 4.0)
                        .padding(.top, 16.0)
                    Text(automationItem.description)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.gray)
                        .padding(.bottom, 8.0)
                    
                    Spacer()
                }
                Spacer()
            }
            .padding(.all, 8.0)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gray.opacity(0.1))
            )
        }
    }
}
