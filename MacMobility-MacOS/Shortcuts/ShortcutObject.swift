//
//  ShortcutObject.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 29/04/2025.
//

import Foundation

public enum ShortcutType: String, Codable {
    case shortcut
    case app
    case webpage
    case utility
    case html
    case control
}

import SwiftUI
import WebKit

struct HTMLCPUView: NSViewRepresentable {
    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()

        // Load local HTML string
        webView.loadHTMLString(htmlContent, baseURL: nil)
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        // No dynamic updates needed
    }

    private var htmlContent: String {
        """
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="UTF-8" />
          <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
          <title>CPU Usage Monitor</title>
          <style>
            body {
              display: flex;
              justify-content: center;
              align-items: center;
              height: 100vh;
              background: #f3f4f6;
              margin: 0;
              font-family: 'Segoe UI', sans-serif;
            }
            #cpu-box {
              width: 300px;
              height: 300px;
              background: white;
              border-radius: 20px;
              box-shadow: 0 10px 30px rgba(0,0,0,0.1);
              padding: 20px;
              box-sizing: border-box;
              display: flex;
              flex-direction: column;
              justify-content: center;
              align-items: center;
              text-align: center;
            }
            #cpu-box h2 {
              margin: 0 0 10px;
              font-size: 24px;
              color: #111827;
            }
            #cpu-box p {
              font-size: 20px;
              margin: 5px 0;
              color: #4b5563;
            }
          </style>
        </head>
        <body>
          <div id="cpu-box">
            <h2>CPU Usage</h2>
            <p id="user">User: -- %</p>
            <p id="sys">System: -- %</p>
            <p id="idle">Idle: -- %</p>
          </div>

          <script>
            async function fetchCpuUsage() {
              const user = (Math.random() * 20).toFixed(2);
              const sys = (Math.random() * 10).toFixed(2);
              const idle = (100 - user - sys).toFixed(2);

              document.getElementById('user').textContent = `User: ${user} %`;
              document.getElementById('sys').textContent = `System: ${sys} %`;
              document.getElementById('idle').textContent = `Idle: ${idle} %`;
            }

            fetchCpuUsage();
            setInterval(fetchCpuUsage, 2000);
          </script>
        </body>
        </html>
        """
    }
}

struct BrightnessVolumeContainerView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.96, green: 0.96, blue: 0.96))
            BrightnessVolumeBarView()
                .padding()
        }
    }
}

struct BrightnessVolumeBarView: View {
    @State private var progress: Double = 0.5 // Initial value

    var body: some View {
        ZStack(alignment: .trailing) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.init(hex: "FF6906"))
                .frame(height: 30)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .shadow(radius: 2)
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(red: 0.96, green: 0.96, blue: 0.96))
                        .frame(width: geometry.size.width * progress)
                    Spacer(minLength: 0)
                }
                .frame(height: 30)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .contentShape(Rectangle())
            }
            .frame(height: 30)
        }
    }
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
    public var index: Int?
    public var indexes: [Int]?
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
    public var category: String?
    public let size: CGSize?
    
    public init(
        type: ShortcutType,
        page: Int,
        index: Int? = nil,
        indexes: [Int]? = nil,
        size: CGSize? = nil,
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
        showTitleOnIcon: Bool = true,
        category: String? = nil
    ) {
        self.page = page
        self.type = type
        self.index = index
        self.indexes = indexes ?? [index ?? 0]
        self.path = path
        self.id = id
        self.title = title
        self.size = size ?? .init(width: 1, height: 1)
        self.color = color
        self.scriptCode = scriptCode
        self.utilityType = utilityType
        self.imageData = imageData
        self.faviconLink = faviconLink
        self.browser = browser
        self.objects = objects
        self.showTitleOnIcon = showTitleOnIcon
        self.category = category
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.index = try container.decodeIfPresent(Int.self, forKey: .index)
        self.indexes = try container.decodeIfPresent([Int].self, forKey: .indexes) ?? [self.index ?? 0]
        self.page = try container.decode(Int.self, forKey: .page)
        self.id = try container.decode(String.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.path = try container.decodeIfPresent(String.self, forKey: .path)
        self.color = try container.decodeIfPresent(String.self, forKey: .color)
        self.faviconLink = try container.decodeIfPresent(String.self, forKey: .faviconLink)
        self.type = try container.decode(ShortcutType.self, forKey: .type)
        self.imageData = try container.decodeIfPresent(Data.self, forKey: .imageData)
        self.browser = try container.decodeIfPresent(Browsers.self, forKey: .browser)
        self.scriptCode = try container.decodeIfPresent(String.self, forKey: .scriptCode)
        self.utilityType = try container.decodeIfPresent(UtilityObject.UtilityType.self, forKey: .utilityType)
        self.objects = try container.decodeIfPresent([ShortcutObject].self, forKey: .objects)
        self.showTitleOnIcon = try container.decodeIfPresent(Bool.self, forKey: .showTitleOnIcon)
        self.category = try container.decodeIfPresent(String.self, forKey: .category)
        self.size = try container.decodeIfPresent(CGSize.self, forKey: .size)
    }
}
