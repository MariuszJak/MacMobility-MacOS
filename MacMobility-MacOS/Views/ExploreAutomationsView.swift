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
    case html
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
    var showsTitle: Bool?
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
    private var originalData: [AutomationItem] = []
    @Published var automations: [AutomationItem] = []
    @Published var searchText: String = ""
    @Published var tab: StoreTab = .automations
    private var tmp: [AutomationItem] = []
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        bind()
    }
    
    func loadJSONFromDirectory() {
        let test: AutomationsList = loadJSON("automations")
        self.automations = test.automations
        self.originalData = self.automations
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
                        self.tmp = filterByType(tab: self.tab)
                    } else {
                        self.automations = self.tmp.filter { $0.title.lowercased().contains(text.lowercased()) }
                    }
                }
            }
            .store(in: &cancellables)
        
        $tab
            .receive(on: RunLoop.main)
            .sink { [weak self] tab in
                guard let self else { return }
                automations = filterByType(tab: tab)
            }
            .store(in: &cancellables)
    }
    
    func filterByType(tab: StoreTab) -> [AutomationItem] {
        var automations = originalData
        automations = automations.filter { $0.scripts.contains(where: { $0.type == tab.type }) }
        if tab == .raycast {
            automations = automations.filter { $0.title.contains("Raycast") }
        }
        return automations
    }
}

struct ExploreAutomationsView: View {
    @ObservedObject private var viewModel = ExploreAutomationsViewModel()
    var openDetailsPage: (AutomationItem) -> Void
    @Namespace private var animation
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Text("Store")
                    .font(.system(size: 21, weight: .bold))
                    .padding(.bottom, 18.0)
                Spacer()
                
            }
            HStack {
                StoreTabBar(selectedTab: $viewModel.tab, animation: animation) {}
                    .frame(maxWidth: .infinity)
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
                .padding()
            }
            .background(
                RoundedBackgroundView()
            )
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

enum StoreTab: Int, CaseIterable {
    case automations, raycast, widgets

    var title: String {
        switch self {
        case .automations: return "Automations"
        case .raycast: return "Raycast"
        case .widgets: return "Widgets"
        }
    }

    var icon: String {
        switch self {
        case .automations: return "app"
        case .raycast: return "square.and.arrow.down.on.square.fill"
        case .widgets: return "link"
        }
    }
    
    var type: AutomationType {
        switch self {
        case .automations:
            return .automator
        case .raycast:
            return .bash
        case .widgets:
            return .html
        }
    }
}

struct StoreTabBar: View {
    @Binding var selectedTab: StoreTab
    var animation: Namespace.ID
    var didSwitch: () -> Void
    
    init(selectedTab: Binding<StoreTab>, animation: Namespace.ID, didSwitch: @escaping () -> Void) {
        self._selectedTab = selectedTab
        self.animation = animation
        self.didSwitch = didSwitch
    }

    var body: some View {
        HStack(spacing: 16) {
            ForEach(StoreTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        selectedTab = tab
                        didSwitch()
                    }
                }) {
                    HStack {
                        Text(tab.title)
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundStyle(selectedTab == tab ? .white : .primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                    .background(
                        ZStack {
                            if selectedTab == tab {
                                Capsule()
                                    .fill(Color.accentColor)
                                    .matchedGeometryEffect(id: "tabBackground", in: animation)
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
        )
        .padding(.horizontal)
    }
}
