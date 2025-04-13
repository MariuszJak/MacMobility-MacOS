//
//  UpdateScreenView.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 13/04/2025.
//

import Foundation
import SwiftUI

class UpdateScreenViewModel: ObservableObject {
    @Inject var appUpdatesManager: UpdatesManager
    @Published var isUpdating: Bool = false
    let updateData: AppUpdateResponse
    
    init(updateData: AppUpdateResponse) {
        self.updateData = updateData
    }
    
    func updateApp() {
        isUpdating = true
        appUpdatesManager.downloadAndInstallUpdate {
            self.isUpdating = false
        }
    }
}

struct UpdateScreenView: View {
    @ObservedObject private var viewModel: UpdateScreenViewModel
    
    init(viewModel: UpdateScreenViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(alignment: .leading) {
            Text("App Update ver. \(viewModel.updateData.latest_version)")
                .font(.system(size: 24.0, weight: .bold))
                .padding(.bottom, 24.0)
                .padding(.top, 16.0)
            Divider()
            Text("Details")
                .font(.system(size: 18.0))
                .padding(.bottom, 12.0)
                .padding(.top, 12.0)
            Text(viewModel.updateData.release_notes)
                .font(.system(size: 14.0))
            Spacer()
            if viewModel.isUpdating {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(0.7)
                    .padding(.bottom, 18.0)
                    .padding(.leading, 24.0)
            } else {
                Button {
                    viewModel.updateApp()
                } label: {
                    Text("Install Update")
                        .foregroundStyle(Color.green)
                }
                .padding(.bottom, 24.0)
            }
        }
        .onAppear {
            for window in NSApplication.shared.windows {
                window.appearance = NSAppearance(named: .darkAqua)
            }
        }
        .padding(.horizontal, 21.0)
    }
}
