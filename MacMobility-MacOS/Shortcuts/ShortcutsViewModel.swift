//
//  ShortcutsViewModel.swift
//  MacMobility-MacOS
//
//  Created by CoderBlocks on 16/03/2025.
//

import SwiftUI
import Combine

public enum ShortcutType: String, Codable {
    case shortcut
    case app
    case webpage
    case utility
}

extension Array where Element: Equatable {
    mutating func appendUnique(contentsOf newElements: [Element]) {
        for element in newElements {
            if !self.contains(element) {
                self.append(element)
            }
        }
    }
}

public struct ShortcutObject: Identifiable, Codable, Equatable {
    public let index: Int?
    public var page: Int
    public let id: String
    public let title: String
    public var path: String?
    public var color: String?
    public var faviconLink: String?
    public let type: ShortcutType
    public var imageData: Data?
    public var browser: Browsers?
    public var scriptCode: String?
    public var utilityType: UtilityObject.UtilityType?
    public var objects: [ShortcutObject]?
    public var showTitleOnIcon: Bool?
    
    public init(
        type: ShortcutType,
        page: Int,
        index: Int? = nil,
        path: String? = nil,
        id: String,
        title: String,
        color: String? = nil,
        faviconLink: String? = nil,
        browser: Browsers? = nil,
        imageData: Data? = nil,
        scriptCode: String? = nil,
        utilityType: UtilityObject.UtilityType? = nil,
        objects: [ShortcutObject]? = nil,
        showTitleOnIcon: Bool = true
    ) {
        self.page = page
        self.type = type
        self.index = index
        self.path = path
        self.id = id
        self.title = title
        self.color = color
        self.scriptCode = scriptCode
        self.utilityType = utilityType
        self.imageData = imageData
        self.faviconLink = faviconLink
        self.browser = browser
        self.objects = objects
        self.showTitleOnIcon = showTitleOnIcon
    }
}

public class ShortcutsViewModel: ObservableObject, WebpagesWindowDelegate, UtilitiesWindowDelegate {
    let connectionManager: ConnectionManager
    @Published var configuredShortcuts: [ShortcutObject] = []
    @Published var shortcuts: [ShortcutObject] = []
    @Published var installedApps: [ShortcutObject] = []
    @Published var appsAddedByUser: [ShortcutObject] = []
    @Published var webpages: [ShortcutObject] = []
    @Published var utilities: [ShortcutObject] = []
    @Published var searchText: String = ""
    @Published var cancellables = Set<AnyCancellable>()
    @Published var pages = 1
    @Published var scrollToApp: String = ""
    @Published var scrollToPage: Int = 0
    @Published var availablePeerName: String = ""
    var close: () -> Void = {}
    private var timer: Timer?
    public var testColor = "#6DDADE"
    private var allWebpages: [ShortcutObject] = []
    private var cachedIcons: [String: Data] = [:]
    private var tmpAllItems: [ShortcutObject] = []
    private var setupMode: SetupMode?
    private var website: WebsiteTest?
    
    init(connectionManager: ConnectionManager) {
//        UserDefaults.standard.clearAll()
        self.connectionManager = connectionManager
        self.configuredShortcuts = UserDefaults.standard.get(key: .shortcuts) ?? []
        self.webpages = UserDefaults.standard.get(key: .webItems) ?? []
        self.utilities = UserDefaults.standard.get(key: .utilities) ?? []
        self.pages = UserDefaults.standard.get(key: .pages) ?? 1
        self.appsAddedByUser = UserDefaults.standard.get(key: .userApps) ?? []
        fetchShortcuts()
        fetchInstalledApps()
        registerListener()
        startMonitoring()
    }
    
    func registerListener() {
        $searchText
            .receive(on: RunLoop.main)
            .sink { [weak self] text in
                guard let self else { return }
                if text.isEmpty {
                    self.tmpAllItems.removeAll()
                } else {
                    tmpAllItems.appendUnique(contentsOf: installedApps + shortcuts + webpages + utilities + appsAddedByUser)
                }
                self.fetchShortcuts()
                self.fetchInstalledApps()
                self.searchWebpages()
                self.searchUtilities()
            }
            .store(in: &cancellables)
        
        connectionManager.$initialSetup
            .receive(on: DispatchQueue.main)
            .sink { [weak self] setupMode in
                self?.setupMode = setupMode
            }
            .store(in: &cancellables)
        
        connectionManager.$website
            .receive(on: DispatchQueue.main)
            .sink { [weak self] website in
                self?.website = website
            }
            .store(in: &cancellables)
        
        connectionManager.$automatedActions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] options in
                self?.handleAutomatedActions(options)
            }
            .store(in: &cancellables)
    }
    
    func isAppAddedByUser(path: String) -> Bool {
        appsAddedByUser.contains(where: { $0.path == path })
    }
    
    func removeAppInstalledByUser(path: String) {
        appsAddedByUser = appsAddedByUser.filter { $0.path != path }
        installedApps = installedApps.filter { $0.path != path }
        configuredShortcuts.removeAll { $0.path == path }
        connectionManager.shortcuts = configuredShortcuts
        UserDefaults.standard.store(configuredShortcuts, for: .shortcuts)
        UserDefaults.standard.store(appsAddedByUser, for: .userApps)
    }
    
    func handleAutomatedActions(_ options: [AutomationOption]?) {
        guard let options, let setupMode else {
            return
        }
        
        options.forEach { option in
            addAutomations(
                from: setupMode.type == .advanced
                ? option.scripts
                : option.scripts.filter { !($0.isAdvanced ?? false) }
            )
            if option.title == "macOS System" {
                let filtered = setupMode.type == .advanced
                ? option.scripts
                : option.scripts.filter { !($0.isAdvanced ?? false) }
                var i: Int = 0
                filtered.enumerated().forEach { (index, script) in
                    i += 1
                    let so: ShortcutObject = .from(script: script, at: index)
                    addConfiguredShortcut(object: so)
                }
                if let website = website {
                    let so: ShortcutObject = .init(type: .webpage, page: 1, index: i, path: website.url, id: UUID().uuidString, title: "", color: nil, faviconLink: nil, browser: .safari, imageData: website.nsImage?.toData, scriptCode: nil, utilityType: nil, objects: nil, showTitleOnIcon: false)
                    saveWebpage(with: so)
                    addConfiguredShortcut(object: so)
                }
            }
        }
    }
    
    func objectAt(index: Int, page: Int) -> ShortcutObject? {
        configuredShortcuts.filter { $0.page == page }.first(where: { $0.index == index })
    }
    
    func object(for id: String) -> ShortcutObject? {
        if searchText.isEmpty {
            shortcuts.first { $0.id == id } ?? installedApps.first { $0.id == id } ?? webpages.first { $0.id == id } ?? utilities.first { $0.id == id }
        } else {
            tmpAllItems.first { $0.id == id }
        }
    }
    
    func allObjects() -> [ShortcutObject] {
        shortcuts + installedApps + webpages + utilities
    }
    
    func removeShortcut(id: String) {
        configuredShortcuts.removeAll { $0.id == id }
        connectionManager.shortcuts = configuredShortcuts
        UserDefaults.standard.store(configuredShortcuts, for: .shortcuts)
    }
    
    func addPage() {
        pages += 1
        scrollToPage = pages
        UserDefaults.standard.store(pages, for: .pages)
    }
    
    func removePage(with number: Int) {
        configuredShortcuts.removeAll { $0.page == number }
        configuredShortcuts.enumerated().forEach { (index, object) in
            if configuredShortcuts[index].page > number {
                configuredShortcuts[index].page -= 1
            }
        }
        if pages > 1 {
            pages -= 1
        }
        connectionManager.shortcuts = configuredShortcuts
        UserDefaults.standard.store(configuredShortcuts, for: .shortcuts)
        UserDefaults.standard.store(pages, for: .pages)
    }
    
    func removeWebItem(id: String) {
        webpages.removeAll { $0.id == id }
        configuredShortcuts.removeAll { $0.id == id }
        UserDefaults.standard.store(webpages, for: .webItems)
        connectionManager.shortcuts = configuredShortcuts
        UserDefaults.standard.store(configuredShortcuts, for: .shortcuts)
    }
    
    func removeUtilityItem(id: String) {
        utilities.removeAll { $0.id == id }
        configuredShortcuts.removeAll { $0.id == id }
        UserDefaults.standard.store(utilities, for: .utilities)
        connectionManager.shortcuts = configuredShortcuts
        UserDefaults.standard.store(configuredShortcuts, for: .shortcuts)
    }
    
    func addAutomations(from scripts: [AutomationScript]) {
        let shortcuts: [ShortcutObject] = scripts.map { ShortcutObject.from(script: $0) }
        shortcuts.forEach { object in
            saveUtility(with: object)
        }
    }
    
    func addConfiguredShortcut(object: ShortcutObject) {
        if let index = configuredShortcuts.firstIndex(where: { $0.index == object.index && $0.page == object.page }) {
            let oldObject = configuredShortcuts[index]
            configuredShortcuts[index] = object
            configuredShortcuts.enumerated().forEach { (index, shortcut) in
                if (object.index != shortcut.index && shortcut.id == object.id) {
                    configuredShortcuts[index] = .init(
                        type: oldObject.type,
                        page: configuredShortcuts[index].page,
                        index: configuredShortcuts[index].index,
                        path: oldObject.path,
                        id: oldObject.id,
                        title: oldObject.title,
                        color: oldObject.color,
                        faviconLink: oldObject.faviconLink,
                        browser: oldObject.browser,
                        imageData: oldObject.imageData,
                        scriptCode: oldObject.scriptCode,
                        utilityType: oldObject.utilityType,
                        objects: oldObject.objects,
                        showTitleOnIcon: oldObject.showTitleOnIcon ?? true
                    )
                }
            }
        } else {
            configuredShortcuts = configuredShortcuts.filter { $0.id != object.id }
            configuredShortcuts.append(object)
        }
        connectionManager.shortcuts = configuredShortcuts
        UserDefaults.standard.store(configuredShortcuts, for: .shortcuts)
    }
    
    func searchWebpages() {
        webpages.enumerated().forEach { (index, webpage) in
            if searchText.isEmpty {
                webpages[index].scriptCode = ""
            } else {
                webpages[index].scriptCode = webpage.title.lowercased().contains(self.searchText.lowercased()) ? "" : "Hidden"
            }
        }
    }
    
    func searchUtilities() {
        utilities.enumerated().forEach { (index, utility) in
            if searchText.isEmpty {
                utilities[index].path = ""
            } else {
                utilities[index].path = utility.title.lowercased().contains(self.searchText.lowercased()) ? "" : "Hidden"
            }
        }
    }
    
    func fetchShortcuts() {
        shortcuts = getShortcutsList()
        configuredShortcuts.filter { $0.type == .shortcut }.forEach { configuredShortcut in
            let shortcutExists = shortcuts.contains(where: { $0.id == configuredShortcut.id })
            if !shortcutExists {
                if let index = configuredShortcuts.firstIndex(where: { $0.id == configuredShortcut.id }) {
                    configuredShortcuts.remove(at: index)
                    connectionManager.shortcuts = configuredShortcuts
                    UserDefaults.standard.store(configuredShortcuts, for: .shortcuts)
                }
            }
        }
    }
    
    func saveWebpage(with webpageItem: ShortcutObject) {
        if let index = webpages.firstIndex(where: { $0.id == webpageItem.id }) {
            webpages[index] = webpageItem
            if let configuredIndex = configuredShortcuts.firstIndex(where: { $0.id == webpageItem.id }) {
                configuredShortcuts[configuredIndex] = .init(
                    type: webpageItem.type,
                    page: configuredShortcuts[configuredIndex].page,
                    index: configuredShortcuts[configuredIndex].index,
                    path: webpageItem.path,
                    id: webpageItem.id,
                    title: webpageItem.title,
                    color: webpageItem.color,
                    faviconLink: webpageItem.faviconLink,
                    browser: webpageItem.browser,
                    imageData: webpageItem.imageData,
                    objects: webpageItem.objects,
                    showTitleOnIcon: webpageItem.showTitleOnIcon ?? true
                )
                UserDefaults.standard.store(configuredShortcuts, for: .shortcuts)
            }
        } else {
            webpages.insert(webpageItem, at: 0)
        }
        connectionManager.shortcuts = configuredShortcuts
        UserDefaults.standard.store(webpages, for: .webItems)
    }
    
    func saveUtility(with utilityItem: ShortcutObject) {
        if let index = utilities.firstIndex(where: { $0.id == utilityItem.id }) {
            utilities[index] = utilityItem
            if let configuredIndex = configuredShortcuts.firstIndex(where: { $0.id == utilityItem.id }) {
                configuredShortcuts[configuredIndex] = .init(
                    type: utilityItem.type,
                    page: configuredShortcuts[configuredIndex].page,
                    index: configuredShortcuts[configuredIndex].index,
                    path: utilityItem.path,
                    id: utilityItem.id,
                    title: utilityItem.title,
                    color: utilityItem.color,
                    faviconLink: utilityItem.faviconLink,
                    browser: utilityItem.browser,
                    imageData: utilityItem.imageData,
                    scriptCode: utilityItem.scriptCode,
                    utilityType: utilityItem.utilityType,
                    objects: utilityItem.objects,
                    showTitleOnIcon: utilityItem.showTitleOnIcon ?? true
                )
                UserDefaults.standard.store(configuredShortcuts, for: .shortcuts)
            }
        } else {
            utilities.insert(utilityItem, at: 0)
        }
        connectionManager.shortcuts = configuredShortcuts
        UserDefaults.standard.store(utilities, for: .utilities)
    }
    
    func openShortcut(name: String) {
        if let url = URL(string: "shortcuts://run-shortcut?name=\(name)") {
            NSWorkspace.shared.open(url)
        }
    }
    
    func getShortcutsList() -> [ShortcutObject] {
        let process = Process()
        let pipe = Pipe()
        
        process.launchPath = "/usr/bin/shortcuts"
        process.arguments = ["list"]
        process.standardOutput = pipe
        
        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)
            let list = output?.components(separatedBy: "\n")
                .filter { !$0.isEmpty }
            
            if self.searchText.isEmpty {
                return list?.map {
                    item in .init(
                        type: .shortcut,
                        page: 1,
                        id: shortcuts.first(where: { shortcut in item == shortcut.title })?.id
                        ?? configuredShortcuts.first(where: { shortcut in item == shortcut.title })?.id
                        ?? UUID().uuidString,
                        title: item,
                        color: testColor,
                        imageData: NSImage(named: "shortcuts")?.tiffRepresentation
                    )
                } ?? []
            } else {
                return list?.filter { $0.lowercased().contains(self.searchText.lowercased()) }
                    .map {
                        item in .init(
                            type: .shortcut,
                            page: 1,
                            id: shortcuts.first(where: { shortcut in item == shortcut.title })?.id
                            ?? configuredShortcuts.first(where: { shortcut in item == shortcut.title })?.id
                            ?? UUID().uuidString,
                            title: item,
                            color: testColor,
                            imageData: NSImage(named: "shortcuts")?.tiffRepresentation
                        )
                    } ?? []
            }
        } catch {
            print("Failed to fetch shortcuts: \(error)")
            return []
        }
    }
    
    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            self?.fetchShortcuts()
        }
    }
    
    deinit {
        timer?.invalidate()
    }
    
    func fetchInstalledApps() {
        let appDirectories = [
            "/Applications",
            "/System/Applications/Utilities"
        ]

        var apps: [ShortcutObject] = []

        for directory in appDirectories {
            apps.append(contentsOf: findApps(in: directory))
        }

        DispatchQueue.main.async {
            if self.searchText.isEmpty {
                self.installedApps = apps.sorted { $0.title.lowercased() < $1.title.lowercased() }
            } else {
                self.installedApps = apps.sorted { $0.title.lowercased() < $1.title.lowercased() }
                    .filter { $0.title.lowercased().contains(self.searchText.lowercased()) }
            }
        }
        
        appsAddedByUser.forEach { userApp in
            if apps.contains(where: { $0.path != userApp.path }) {
                apps.append(userApp)
            }
        }
    }
    
    func addInstalledApp(for path: String) {
        guard installedApps.first(where: { $0.path == path }) == nil else {
            if let index = installedApps.firstIndex(where: { $0.path == path }) {
                installedApps[index].imageData = getIcon(fromAppPath: path)
            }
            scrollToApp = path.appNameFromPath() ?? "Unknown"
            return
        }
        let title = path.appNameFromPath() ?? "Unknown"
        let app = ShortcutObject(
            type: .app,
            page: configuredShortcuts.first(where: { shortcut in path == shortcut.path })?.page ?? 1,
            path: path,
            id: appsAddedByUser.first(where: { shortcut in path == shortcut.path })?.id ?? configuredShortcuts.first(where: { shortcut in path == shortcut.path })?.id ?? UUID().uuidString,
            title: title,
            imageData: cachedIcons[path] ?? getIcon(fromAppPath: path)
        )
        appsAddedByUser.insert(app, at: 0)
        fetchInstalledApps()
        scrollToApp = title
        UserDefaults.standard.store(appsAddedByUser, for: .userApps)
        searchText = searchText
    }
    
    func findApps(in directory: String) -> [ShortcutObject] {
        var apps: [ShortcutObject] = []

        if let appURLs = try? FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: directory), includingPropertiesForKeys: nil, options: .skipsHiddenFiles) {
            for appURL in appURLs where appURL.pathExtension == "app" {
                let appName = appURL.deletingPathExtension().lastPathComponent
                apps.append(
                    ShortcutObject(
                        type: .app,
                        page: configuredShortcuts.first(where: { shortcut in appURL.path == shortcut.path })?.page ?? 1,
                        path: appURL.path,
                        id: installedApps.first(where: { shortcut in appURL.path == shortcut.path })?.id ?? configuredShortcuts.first(where: { shortcut in appURL.path == shortcut.path })?.id ?? UUID().uuidString,
                        title: appName,
                        imageData: cachedIcons[appURL.path] ?? getIcon(fromAppPath: appURL.path)
                    )
                )
            }
        }

        return apps
    }
    
    var countMB = 0.0
    
    func getIcon(fromAppPath appPath: String?) -> Data? {
        guard let appPath else {
            return nil
        }
        let bundleURL = URL(fileURLWithPath: appPath)
        
        guard let bundle = Bundle(url: bundleURL) else {
            return nil
        }
        
        guard let iconFile = bundle.infoDictionary?["CFBundleIconFile"] as? String else {
            let icon = NSWorkspace.shared.icon(forFile: appPath)
            let resizedIcon = icon.resizedImage(newSize: .init(width: 68.0, height: 68.0))
            let fallbackIcon = try? resizedIcon.imageData(for: .png(scale: 0.2, excludeGPSData: false))
            return fallbackIcon
        }
        
        let iconName = (iconFile as NSString).deletingPathExtension
        let iconExtension = (iconFile as NSString).pathExtension.isEmpty ? "icns" : (iconFile as NSString).pathExtension
        
        guard let iconPath = bundle.path(forResource: iconName, ofType: iconExtension) else {
            return nil
        }
        let pngProps: [NSBitmapImageRep.PropertyKey: Any] = [
            .compressionFactor: 0.0
        ]
        guard let icon = NSImage(contentsOfFile: iconPath) else {
            return nil
        }
        let resized = icon.resizedImage(newSize: .init(width: 96.0, height: 96.0))
        guard let tiffData = resized.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiffData),
           let pngData = bitmap.representation(using: .png, properties: pngProps) else {
            return nil
        }
        cachedIcons[appPath] = pngData
        
//        let sizeInMB = Double(pngData.count) / (1024.0 * 1024.0)
//        countMB += sizeInMB
//        print(String(format: "%.8f MB", countMB))
        
        return pngData
    }
}

extension String {
    func appNameFromPath() -> String? {
        guard let lastComponent = self.split(separator: "/").last,
              lastComponent.hasSuffix(".app") else {
            return nil
        }
        return lastComponent.replacingOccurrences(of: ".app", with: "")
    }
}

// ---

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
                    }
                }
                .padding(.trailing, 21.0)
                VStack(alignment: .leading) {
                    Spacer()
                    Text(automationItem.title)
                        .font(.system(size: 21, weight: .bold))
                        .padding(.bottom, 4.0)
                    Text(automationItem.description)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.gray)
                        .padding(.bottom, 8.0)
                    
                    Spacer()
                }
            }
            .padding(.all, 8.0)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gray.opacity(0.1))
            )
        }
        .onAppear {
            for window in NSApplication.shared.windows {
                window.appearance = NSAppearance(named: .darkAqua)
            }
        }
    }
}

// -----

struct AutomationInstallView: View {
    var automationItem: AutomationItem
    var selectedScriptsAction: ([AutomationScript]) -> Void
    
    @State private var selectedScriptIDs: Set<UUID>
    
    init(automationItem: AutomationItem, selectedScriptsAction: @escaping ([AutomationScript]) -> Void) {
        self.automationItem = automationItem
        self.selectedScriptsAction = selectedScriptsAction
        _selectedScriptIDs = State(initialValue: Set(automationItem.scripts.map { $0.id }))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 12) {
                if let imageData = automationItem.imageData,
                   let nsImage = NSImage(data: imageData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Image(systemName: "bolt.fill")
                        .resizable()
                        .frame(width: 48, height: 48)
                        .foregroundColor(.accentColor)
                }
                
                Text(automationItem.title)
                    .font(.title)
                    .bold()
            }
            .padding(.top)
            
            Divider()
            
            // Scripts section
            VStack(alignment: .leading, spacing: 12) {
                Text("Scripts")
                    .font(.headline)
                
                ScrollView {
                    ForEach(automationItem.scripts) { script in
                        HStack(alignment: .top) {
                            VStack(alignment: .leading) {
                                Toggle(isOn: Binding(
                                    get: {
                                        selectedScriptIDs.contains(script.id)
                                    },
                                    set: { isSelected in
                                        if isSelected {
                                            selectedScriptIDs.insert(script.id)
                                        } else {
                                            selectedScriptIDs.remove(script.id)
                                        }
                                    }
                                )) {
                                    Text(script.name)
                                        .font(.system(size: 14))
                                        .padding(.bottom, 8.0)
                                }
                                Text(script.description)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.gray)
                                    .padding(.bottom, 8.0)
                            }
                        }
                    }
                }
            }
            
            Spacer()
            
            HStack {
                Spacer()
                Button("Install") {
                    let selectedScripts = automationItem.scripts.filter { selectedScriptIDs.contains($0.id) }
                    selectedScriptsAction(selectedScripts)
                }
                .keyboardShortcut(.defaultAction)
                Spacer()
            }
            .padding(.bottom)
        }
        .padding()
        .frame(minWidth: 400, minHeight: 400)
    }
}


//------

protocol JSONLoadable {
    func loadJSON<T: Decodable>(_ filename: String) -> T
}

extension JSONLoadable {
    func loadJSON<T: Decodable>(_ filename: String) -> T {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            fatalError("Failed to locate \(filename).json in bundle.")
        }

        guard let data = try? Data(contentsOf: url) else {
            fatalError("Failed to load \(filename).json from bundle.")
        }

        let decoder = JSONDecoder()
        guard let loaded = try? decoder.decode(T.self, from: data) else {
            fatalError("Failed to decode \(filename).json from bundle.")
        }

        return loaded
    }
}

extension ShortcutObject {
    static func from(script: AutomationScript, at index: Int? = nil) -> ShortcutObject {
        var utilityType: UtilityObject.UtilityType?
        switch script.type {
        case .automator, .none:
            utilityType = .automation
        case .bash:
            utilityType = .commandline
        }
        return .init(
            type: .utility,
            page: 1,
            index: index,
            path: nil,
            id: script.id.uuidString,
            title: script.name,
            color: nil,
            faviconLink: nil,
            browser: nil,
            imageData: script.imageData,
            scriptCode: script.script,
            utilityType: utilityType,
            objects: nil,
            showTitleOnIcon: false
        )
    }
}
