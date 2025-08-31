//
//  IconSelectorView.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 30/08/2025.
//

import SwiftUI

// MARK: - Models
struct Folder: Codable, Identifiable {
    let id = UUID()
    let name: String
    let subfolders: [Folder]?
    let images: [String]?
    
    enum CodingKeys: String, CodingKey { case name, subfolders, images }
}

extension Folder: Hashable {
    static func == (lhs: Folder, rhs: Folder) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - Root
struct IconSelectorView: View, JSONLoadable {
    @State private var path = NavigationPath()
    @State private var rootFolder: Folder?
    let action: (String) -> Void

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if let folder = rootFolder {
                    FolderScreen(folder: folder, isRoot: true, action: action)
                        .navigationTitle(folder.name)
                        .navigationDestination(for: Folder.self) { sub in
                            FolderScreen(folder: sub, isRoot: false, action: action)
                                .navigationTitle(sub.name)
                        }
                } else {
                    ProgressView("Loading…")
                        .task { rootFolder = loadJSON("structure") }
                }
            }
        }
        .frame(minWidth: 700, minHeight: 480)
    }
}

// MARK: - Folder Screen (recursive)
struct FolderScreen: View {
    let folder: Folder
    let isRoot: Bool
    let action: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            if !isRoot {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Label("Back", systemImage: "chevron.left")
                    }
                    .padding()
                    Spacer()
                }
            }
            List {
                
                if let subs = folder.subfolders, !subs.isEmpty {
                    Section("Folders") {
                        ForEach(subs) { sub in
                            NavigationLink(value: sub) {
                                Label(sub.name, systemImage: "folder")
                            }
                        }
                    }
                }
                if let imgs = folder.images, !imgs.isEmpty {
                    Section("Images") {
                        ImageGrid(images: imgs, action: action)
                            .padding(.vertical, 6)
                    }
                }
            }
        }
    }
}

// MARK: - Image Grid
struct ImageGrid: View, ImageLoadable {
    let images: [String]
    let action: (String) -> Void
    private let columns = [GridItem(.adaptive(minimum: 140), spacing: 16)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(images, id: \.self) { name in
                VStack(spacing: 8) {
                    if let nsImage = loadImage(named: name) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 140)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(.quaternary))
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10).fill(.quaternary)
                            Image(systemName: "photo")
                                .font(.system(size: 36))
                                .foregroundStyle(.secondary)
                        }
                        .frame(height: 140)
                    }
                    Text(name)
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .onTapGesture {
                    action(name)
                }
                .padding(6)
            }
        }
    }
}
