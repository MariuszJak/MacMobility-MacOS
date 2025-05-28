//
//  ExploreAutomationsView.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 29/04/2025.
//

import SwiftUI
import Combine

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
    @Published var searchText: String = ""
    private var tmp: [AutomationItem] = []
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        bind()
    }
    
    func loadJSONFromDirectory() {
        let test: AutomationsList = loadJSON("automations")
        self.automations = test.automations
    }
    
    func bind() {
        $searchText
            .receive(on: RunLoop.main)
            .sink { [weak self] text in
                guard let self else { return }
                if text.isEmpty, !tmp.isEmpty {
                    self.automations = self.tmp
                    self.tmp.removeAll()
                } else {
                    if tmp.isEmpty {
                        self.tmp = automations
                    } else {
                        self.automations = self.tmp.filter { $0.title.lowercased().contains(text.lowercased()) }
                    }
                }
            }
            .store(in: &cancellables)
    }
}

struct ExploreAutomationsView: View {
    @ObservedObject private var viewModel = ExploreAutomationsViewModel()
    var openDetailsPage: (AutomationItem) -> Void
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Text("Install Automations")
                    .font(.system(size: 21, weight: .bold))
                    .padding(.bottom, 18.0)
                Spacer()
                AnimatedSearchBar(searchText: $viewModel.searchText)
                    .padding(.all, 3.0)
            }
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
