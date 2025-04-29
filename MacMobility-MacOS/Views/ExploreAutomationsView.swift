//
//  ExploreAutomationsView.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 29/04/2025.
//

import SwiftUI

struct AutomationsList: Codable {
    let automations: [AutomationItem]
}

enum AutomationType: String, Codable {
    case bash
    case automator
}

struct AutomationScript: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var description: String
    var script: String
    var imageData: Data?
    var imageName: String?
    var type: AutomationType?
    var isAdvanced: Bool?
    var category: String?
}

struct AutomationItem: Identifiable, Codable {
    var id = UUID()
    var title: String
    var description: String
    var imageData: Data?
    var imageName: String?
    var scripts: [AutomationScript]
}

class ExploreAutomationsViewModel: ObservableObject, JSONLoadable {
    @Published var automations: [AutomationItem] = []
    
    func loadJSONFromDirectory() {
        let test: AutomationsList = loadJSON("automations")
        self.automations = test.automations
    }
}

struct ExploreAutomationsView: View {
    @ObservedObject private var viewModel = ExploreAutomationsViewModel()
    var openDetailsPage: (AutomationItem) -> Void
    
    var body: some View {
        VStack {
            Text("Install Automations")
                .font(.system(size: 21, weight: .bold))
                .padding(.bottom, 18.0)
            Divider()
                .padding(.bottom, 14.0)
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 400))], spacing: 6) {
                    ForEach(viewModel.automations) { automationItem in
                        InstallAutomationsView(automationItem: automationItem) {
                            openDetailsPage(automationItem)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .onAppear {
            viewModel.loadJSONFromDirectory()
            for window in NSApplication.shared.windows {
                window.appearance = NSAppearance(named: .darkAqua)
            }
        }
        .padding()
    }
}
