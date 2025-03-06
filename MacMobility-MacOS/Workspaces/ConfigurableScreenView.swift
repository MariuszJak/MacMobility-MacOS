//
//  ConfigurableScreenView.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 06/03/2025.
//

import Foundation
import SwiftUI

struct ConfigurableScreenView: View {
    @StateObject var viewModel: ConfigurableScreenViewModel
    private let id: String
    
    init(id: String, viewModel: ConfigurableScreenViewModel) {
        self._viewModel = .init(wrappedValue: viewModel)
        self.id = id
    }
    
    var body: some View {
        VStack {
            HStack {
                ScreenTypeView(id: id, screenType: viewModel.screenType, size: .medium, apps: viewModel.apps, removeAction: viewModel.removeAction, addAction: viewModel.addAction)
                VStack {
                    Button {
                        viewModel.screenType = .singleScreen
                        viewModel.resetToSingleScreen()
                    } label: {
                        ScreenTypeView(id: "1", screenType: .singleScreen, size: .small, apps: nil, addAction: { _ in})
                    }
                    .background(viewModel.screenType == .singleScreen ? Color.blue : Color.clear)
                    Button {
                        viewModel.screenType = .splitScreenHorizontal
                    } label: {
                        ScreenTypeView(id: "2", screenType: .splitScreenHorizontal, size: .small, apps: nil, addAction: { _ in })
                    }
                    .background(viewModel.screenType == .splitScreenHorizontal ? Color.blue : Color.clear)
                }
                .frame(width: 45)
            }
        }
        .frame(width: 280, height: 140)
        .background(
            RoundedRectangle(cornerRadius: 20.0)
                .fill(Color.black.opacity(0.4))
        )
    }
}
