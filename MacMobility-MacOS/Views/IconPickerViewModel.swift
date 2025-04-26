//
//  IconPickerViewModel.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 21/04/2025.
//

import SwiftUI
import AppKit
import Combine

class IconPickerViewModel: ObservableObject {
    @Published var selectedImage: NSImage?
    @Published var searchText: String?
    @Published var isFetchingIcon: Bool = false
    private let shouldAutofetchImage: Bool
    var userSelectedIconAction: (() -> Void)?
    var completion: (NSImage) -> Void
    private var cancellables = Set<AnyCancellable>()
    let resizeSize: CGSize = .init(width: 150, height: 150)
    
    init(selectedImage: NSImage?,
         shouldAutofetchImage: Bool = true,
         searchText: String = "",
         completion: @escaping (NSImage) -> Void,
         userSelectedIconAction: (() -> Void)? = nil) {
        self._selectedImage = .init(initialValue: selectedImage)
        self._searchText = .init(initialValue: searchText)
        self.shouldAutofetchImage = shouldAutofetchImage
        self.completion = completion
        self.userSelectedIconAction = userSelectedIconAction
        self.registerListeners()
    }
    
    func registerListeners() {
        guard shouldAutofetchImage else { return }
        $searchText
            .receive(on: RunLoop.main)
            .removeDuplicates()
            .sink { text in
                if let text, !text.isEmpty, text.containsValidDomain {
                    self.isFetchingIcon = true
                    self.fetchHighResIcon(from: text) { image in
                        if let image {
                            self.assignImage(image)
                            print("Assigned from 1")
                            self.isFetchingIcon = false
                        } else {
                            self.fetchFaviconFromHTML(for: text) { image in
                                if let image {
                                    self.assignImage(image)
                                    print("Assigned from 2")
                                    self.isFetchingIcon = false
                                } else {
                                    self.fetchFavicon(for: text) { _ in
                                        DispatchQueue.main.async {
                                            self.isFetchingIcon = false
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    self.isFetchingIcon = false
                }
            }
            .store(in: &cancellables)
    }
    
    func pickImage(completion: @escaping (NSImage) -> Void) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        
        if panel.runModal() == .OK, let url = panel.url {
            if let image = NSImage(contentsOf: url) {
                let resized = image.resizedImage(newSize: resizeSize)
                completion(resized)
            }
        }
    }
    
    func assignImage(_ image: NSImage, userSelected: Bool = false) {
        DispatchQueue.main.async {
            let resized = image.resizedImage(newSize: self.resizeSize)
            self.selectedImage = resized
            self.completion(resized)
            if userSelected {
                self.userSelectedIconAction?()
            }
        }
    }
    
    func fetchFavicon(for urlString: String, completion: @escaping (Bool) -> Void) {
        guard var components = URLComponents(string: urlString) else { return }

        if components.scheme == nil {
            components.scheme = "https"
        }

        guard let url = components.url, let host = url.host, let faviconURL = URL(string: "\(url.scheme!)://\(host)/favicon.ico") else { return }
        let task = URLSession.shared.dataTask(with: faviconURL) { data, response, error in
            guard let data = data, error == nil else {
                print("Failed to fetch favicon: \(error?.localizedDescription ?? "Unknown error")")
                completion(false)
                return
            }

            if let image = NSImage(data: data) {
                DispatchQueue.main.async {
                    completion(true)
                    print("Assigned from 3")
                    self.assignImage(image)
                }
            }
        }

        task.resume()
    }
    
    func fetchFaviconFromHTML(for urlString: String, completion: @escaping (NSImage?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let scheme = components?.scheme ?? "https"
        guard let host = components?.host, let baseURL = URL(string: "\(scheme)://\(host)") else {
            completion(nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: baseURL) { data, _, _ in
            guard let data = data,
                  let html = String(data: data, encoding: .utf8) else {
                completion(nil)
                return
            }

            if let range = html.range(of: "<link[^>]*rel=[\"']icon[\"'][^>]*>", options: .regularExpression),
               let hrefRange = html[range].range(of: "href=[\"'][^\"']+[\"']", options: .regularExpression) {

                let hrefString = String(html[range][hrefRange])
                    .replacingOccurrences(of: "href=", with: "")
                    .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))

                let iconURL = URL(string: hrefString, relativeTo: url)!.absoluteURL

                URLSession.shared.dataTask(with: iconURL) { data, _, _ in
                    if let data = data, let image = NSImage(data: data) {
                        DispatchQueue.main.async {
                            completion(image)
                        }
                    } else {
                        completion(nil)
                    }
                }.resume()

            } else {
                completion(nil)
            }
        }

        task.resume()
    }
    
    func fetchHighResIcon(from urlString: String, completion: @escaping (NSImage?) -> Void) {
        let urlString = urlString.applyHTTPS()
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let scheme = components?.scheme ?? "https"
        guard let host = components?.host, let pageURL = URL(string: "\(scheme)://\(host)") else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: pageURL) { data, _, _ in
            guard let data = data,
                  let html = String(data: data, encoding: .utf8) else {
                completion(nil)
                return
            }

            let iconCandidates = self.extractIconLinks(from: html, baseURL: pageURL)
            self.fetchFirstValidImage(from: iconCandidates, completion: completion)
        }.resume()
    }
    
    func extractIconLinks(from html: String, baseURL: URL) -> [URL] {
        var links: [URL] = []
        let appleTouchRegex = try! NSRegularExpression(pattern: "<link[^>]+rel=[\"']apple-touch-icon[^\"']*[\"'][^>]+href=[\"']([^\"']+)[\"']", options: .caseInsensitive)
        links.append(contentsOf: matches(for: appleTouchRegex, in: html, baseURL: baseURL))
        let sizedIconRegex = try! NSRegularExpression(pattern: "<link[^>]+rel=[\"']icon[\"'][^>]*sizes=[\"'][^\"']+[\"'][^>]+href=[\"']([^\"']+)[\"']", options: .caseInsensitive)
        links.append(contentsOf: matches(for: sizedIconRegex, in: html, baseURL: baseURL))
        let ogImageRegex = try! NSRegularExpression(pattern: "<meta[^>]+property=[\"']og:image[\"'][^>]+content=[\"']([^\"']+)[\"']", options: .caseInsensitive)
        links.append(contentsOf: matches(for: ogImageRegex, in: html, baseURL: baseURL))

        return links
    }

    func matches(for regex: NSRegularExpression, in html: String, baseURL: URL) -> [URL] {
        let nsrange = NSRange(html.startIndex..<html.endIndex, in: html)
        return regex.matches(in: html, options: [], range: nsrange).compactMap { match in
            if match.numberOfRanges > 1,
               let range = Range(match.range(at: 1), in: html) {
                let urlString = String(html[range])
                return URL(string: urlString, relativeTo: baseURL)?.absoluteURL
            }
            return nil
        }
    }
    
    func fetchFirstValidImage(from urls: [URL], completion: @escaping (NSImage?) -> Void) {
        let queue = DispatchQueue(label: "icon-fetch-queue")

        var index = 0
        func tryNext() {
            guard index < urls.count else {
                completion(nil)
                return
            }

            let url = urls[index]
            index += 1

            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data, let image = NSImage(data: data) {
                    DispatchQueue.main.async {
                        completion(image)
                    }
                } else {
                    queue.asyncAfter(deadline: .now() + 0.1) {
                        tryNext()
                    }
                }
            }.resume()
        }

        queue.async {
            tryNext()
        }
    }
}
import Foundation

extension String {
    var containsValidDomain: Bool {
        let pattern = #"(?i)\b((?:[a-z0-9-]+\.)+[a-z]{2,})\b"#
        return self.range(of: pattern, options: .regularExpression) != nil
    }
}



