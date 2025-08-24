//
//  UIControlCreateView.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 23/08/2025.
//

import Foundation
import SwiftUI
import CodeEditor

class UIControlCreateViewViewModel: ObservableObject, JSONLoadable {
    var id: String?
    @Published var uiControlType: UIControlType = .slider
    @Published var type: ShortcutType = .control
    @Published var size: CGSize = .init(width: 1, height: 1)
    @Published var path: String = ""
    @Published var title: String = ""
    @Published var category: String = "MacOS"
    @Published var iconData: Data?
    @Published var selectedIcon: NSImage? = NSImage(named: "terminal")
    @Published var scriptCode: String = ""
    @Published var initialScriptCode: String = ""
    @Published var showTitleOnIcon: Bool = true
    @Published var categories: [String] = []
    
    init(categories: [String]) {
        self.categories = categories
    }
    
    func clear() {
        id = nil
        iconData = nil
        title = ""
        category = ""
        scriptCode = ""
        showTitleOnIcon = true
    }
}

struct UIControlCreateView: View {
    @ObservedObject var viewModel: UIControlCreateViewViewModel
    var connectionManager: ConnectionManager
    var closeAction: () -> Void
    weak var delegate: UtilitiesWindowDelegate?
    var currentPage: Int?
    let backgroundColor = Color(.sRGB, red: 0.1, green: 0.1, blue: 0.1, opacity: 0.7)
    
    init(
        type: UIControlType,
        connectionManager: ConnectionManager,
        categories: [String],
        item: ShortcutObject? = nil,
        delegate: UtilitiesWindowDelegate?,
        closeAction: @escaping () -> Void
    ) {
        self.connectionManager = connectionManager
        self.delegate = delegate
        self.closeAction = closeAction
        self.viewModel = UIControlCreateViewViewModel(categories: categories)
        self.viewModel.uiControlType = type
        self.viewModel.selectedIcon = NSImage(named: type.iconName)
        self.viewModel.size = item?.size ?? type.size
        self.viewModel.path = item?.path ?? type.path
        if let item {
            currentPage = item.page
            viewModel.type = item.type
            viewModel.title = item.title
            viewModel.id = item.id
            viewModel.scriptCode = item.scriptCode ?? ""
            viewModel.showTitleOnIcon = item.showTitleOnIcon ?? true
            viewModel.category = item.category ?? ""
            if let data = item.imageData {
                viewModel.selectedIcon = NSImage(data: data)
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .center) {
            Text("UI Control")
                .font(.system(size: 18.0, weight: .bold))
        }
        VStack(alignment: .leading) {
            HStack {
                Text("Title")
                    .font(.system(size: 14, weight: .regular))
                    .padding(.trailing, 4.0)
                RoundedTextField(placeholder: "", text: $viewModel.title)
                HStack(alignment: .center) {
                    Toggle("", isOn: $viewModel.showTitleOnIcon)
                        .padding(.trailing, 6.0)
                        .toggleStyle(.switch)
                    Text("Show title on icon")
                        .font(.system(size: 14.0))
                }
            }
            .padding(.bottom, 6.0)
            .frame(maxWidth: .infinity)
            switch viewModel.uiControlType {
            case .slider:
                VolumeContainerView { value in
                    let scriptCode = viewModel.scriptCode
                    let updatedScript = String(format: scriptCode, value)
                    connectionManager.runInlineBashScript(script: updatedScript)
                }
                .frame(width: 450.0, height: 80.0)
                .padding(.leading, 60.0)
                .padding(.vertical, 16.0)
            case .knob:
                RotaryKnob(title: viewModel.title) { value in
                    let scriptCode = viewModel.scriptCode
                    let updatedScript = String(format: scriptCode, value)
                    connectionManager.runInlineBashScript(script: updatedScript)
                }
                .frame(width: 200, height: 200)
                .padding(.leading, 60.0)
                .padding(.vertical, 16.0)
            }
            HStack(alignment: .top) {
                Text("Initial Value Code")
                    .font(.system(size: 14, weight: .regular))
                
                CodeEditor(
                    source: $viewModel.initialScriptCode,
                    language: .bash,
                    theme: .pojoaque,
                    fontSize: .constant(14.0),
                    flags: .defaultEditorFlags,
                    indentStyle: .system,
                    autoPairs: nil,
                    inset: nil,
                    allowsUndo: true
                )
                .cornerRadius(12.0)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(backgroundColor)
                        .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                )
                .padding(.leading, 16.0)
            }
            .frame(height: 100.0)
            HStack(alignment: .top) {
                Text("Code")
                    .font(.system(size: 14, weight: .regular))
                
                CodeEditor(
                    source: $viewModel.scriptCode,
                    language: .bash,
                    theme: .pojoaque,
                    fontSize: .constant(14.0),
                    flags: .defaultEditorFlags,
                    indentStyle: .system,
                    autoPairs: nil,
                    inset: nil,
                    allowsUndo: true
                )
                .cornerRadius(12.0)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(backgroundColor)
                        .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                )
                .padding(.leading, 16.0)
            }
            HStack {
                Text("Category")
                    .font(.system(size: 14, weight: .regular))
                    .padding(.trailing, 4.0)
                Picker("", selection: Binding(
                    get: {
                        viewModel.categories.contains(viewModel.category) ? viewModel.category : "Other"
                    },
                    set: { newValue in
                        if viewModel.categories.contains(newValue) {
                            viewModel.category = newValue
                        } else {
                            viewModel.category = ""
                        }
                    }
                )) {
                    ForEach(viewModel.categories, id: \.self) { option in
                        Text(option)
                            .tag(option)
                    }
                    Text("Other")
                        .tag("Other")
                }
                .pickerStyle(MenuPickerStyle())
                RoundedTextField(placeholder: "", text: $viewModel.category)
            }
            .padding(.bottom, 6.0)
            .padding(.leading, 60.0)
            .frame(maxWidth: .infinity)
            HStack {
                IconPickerView(viewModel: .init(selectedImage: viewModel.selectedIcon) { image in
                    viewModel.selectedIcon = image
                }, userSelectedIcon: $viewModel.selectedIcon, title: viewModel.showTitleOnIcon ? $viewModel.title : .constant(""))
                .padding(.leading, 60.0)
                
                Spacer()
                BlueButton(title: "Cancel", font: .callout, padding: 12.0, backgroundColor: .gray) {
                    viewModel.clear()
                    closeAction()
                }
                .padding(.trailing, 6.0)
                BlueButton(title: "Save", font: .callout, padding: 12.0) {
                    delegate?.saveUtility(with:
                        .init(
                            type: viewModel.type,
                            page: currentPage ?? 1,
                            size: viewModel.size,
                            path: viewModel.path,
                            id: viewModel.id ?? UUID().uuidString,
                            title: viewModel.title,
                            color: viewModel.initialScriptCode, // "osascript -e 'output volume of (get volume settings)'",
                            imageData: viewModel.selectedIcon?.toData,
                            scriptCode: viewModel.scriptCode,
                            utilityType: .commandline,
                            showTitleOnIcon: viewModel.showTitleOnIcon,
                            category: viewModel.category
                        )
                    )
                    viewModel.clear()
                    closeAction()
                }
            }
            .padding(.trailing, 6.0)
        }
        .frame(minWidth: 500.0)
        .padding()
    }
}

struct VolumeContainerView: View {
    var completion: (Int) -> Void
    var iconSize = 24.0
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.96, green: 0.96, blue: 0.96))
            HStack {
                BarView(completion: completion)
                    .padding(.horizontal, 16.0)
            }
        }
    }
}


import Combine

class Throttler<T> {
    private var cancellable: AnyCancellable?
    private let subject = PassthroughSubject<T, Never>()
    var action: ((T) -> Void)?

    init(seconds: Double = 1) {
        cancellable = subject
            .throttle(for: .seconds(seconds), scheduler: RunLoop.main, latest: true)
            .sink { [weak self] value in
                self?.action?(value)
            }
    }

    func send(_ value: T) {
        subject.send(value)
    }
}

struct BarView: View {
    @State private var progress: Double = 0.5
    @State private var previousValue: Double? = 0.5
    var completion: (Int) -> Void
    var throttler = Throttler<Int>()
    
    init(
        completion: @escaping (Int) -> Void
    ) {
        self.completion = completion
        throttler.action = { value in
            completion(value)
        }
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            RoundedRectangle(cornerRadius: 20)
                .frame(height: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.init(hex: "FF6906"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.black.opacity(0.4))
                        )
                )
                .shadow(color: .black.opacity(0.05), radius: 4)

            GeometryReader { geometry in
                HStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(red: 0.96, green: 0.96, blue: 0.96))
                        .frame(width: geometry.size.width * progress)
                    Spacer(minLength: 0)
                }
                .frame(height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let newProgress = min(max(0, value.location.x / geometry.size.width), 1)
                            progress = newProgress
                            let significantDigits = getFirstTwoDecimalDigits(of: newProgress)
                            
                            if let prev = previousValue {
                                let previousDigits = getFirstTwoDecimalDigits(of: prev)
                                if previousDigits != significantDigits {
                                    let value = Double(round(100 * newProgress) / 100) * 100
                                    throttler.send(Int(value))
                                }
                            }
                            previousValue = newProgress
                        }
                )
            }
            .frame(height: 60)
        }
    }
    
    private func getFirstTwoDecimalDigits(of value: Double) -> (Int, Int) {
        let shifted = value * 100
        let intPart = Int(shifted)
        let first = intPart / 10
        let second = intPart % 10
        return (first, second)
    }
}

struct RotaryKnob: View {
    @State private var angle: Double = 0
    @State private var startAngle: Double = 0
    @State private var dragStartAngle: Double = 0
    private var throttler = Throttler<Int>(seconds: 0.25)
    var completion: (Int) -> Void
    let title: String
    
    init(
        title: String,
        completion: @escaping (Int) -> Void
    ) {
        self.title = title
        self.completion = completion
        throttler.action = { value in
            completion(value)
        }
    }

    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(red: 0.96, green: 0.96, blue: 0.96))
                .shadow(color: .black.opacity(0.05), radius: 4)

            GeometryReader { geo in
                let size = min(geo.size.width, geo.size.height)
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                let knobRadius = size * 0.45
                let markerOffset = knobRadius * 0.75
                let dotOffset = knobRadius * 0.9

                ZStack {
                    // Knob base
                    Circle()
                        .fill(Color(red: 0.95, green: 0.95, blue: 0.95))
                        .shadow(color: .black.opacity(0.08), radius: 4)
                        .overlay(
                            Circle()
                                .stroke(Color.black.opacity(0.4))
                        )
                        .frame(width: knobRadius * 2, height: knobRadius * 2)
                        .position(center)

                    // Fixed top dot
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 8, height: 8)
                        .position(x: center.x, y: center.y - dotOffset)

                    // Rotating marker
                    Circle()
                        .fill(Color(red: 0.95, green: 0.95, blue: 0.95))
                        .frame(width: knobRadius * 2, height: knobRadius * 2)
                        .overlay(
                            Rectangle()
                                .fill(Color.init(hex: "FF6906"))
                                .frame(width: 6, height: markerOffset)
                                .offset(y: -markerOffset / 2)
                        )
                        .rotationEffect(.degrees(angle))
                        .position(center)

                    // Arc from top dot to marker (always visible)
                    ArcFullSweepShape(center: center,
                                      radius: dotOffset,
                                      startDeg: -90,
                                      sweepDeg: angle)
                        .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .foregroundColor(Color.init(hex: "FF6906"))
                        .frame(width: geo.size.width, height: geo.size.height)

                    // Angle text
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                        .position(x: center.x, y: center.y + knobRadius + 20)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let dx = value.location.x - center.x
                            let dy = value.location.y - center.y
                            let dragAngle = atan2(dy, dx) * 180 / .pi
                            
                            if value.startLocation == value.location {
                                startAngle = angle
                                dragStartAngle = dragAngle
                            } else {
                                var delta = dragAngle - dragStartAngle
                                if delta < -180 { delta += 360 }
                                if delta > 180 { delta -= 360 }
                                angle = (startAngle + delta)
                                if angle < 0 { angle += 360 }
                                if angle > 360 { angle.formTruncatingRemainder(dividingBy: 360) }
                                throttler.send(Int(mapKnobValue(angle)))
                            }
                        }
                )
            }
            .frame(width: 200, height: 200)
        }
    }
    
    func mapKnobValue(_ angle: Double) -> Double {
        let minInput = 0.0
        let maxInput = 360.0
        let minOutput = 0.0
        let maxOutput = 100.0
        
        // Map 0–360 → 100–200
        return minOutput + (angle - minInput) * (maxOutput - minOutput) / (maxInput - minInput)
    }
}
