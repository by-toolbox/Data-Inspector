//
//  FileMenu.swift
//  Data Inspector
//
//  Created by Axel Martinez on 20/11/24.
//

import UniformTypeIdentifiers
import SwiftUI
import SQLiteNIO

struct FileMenu: View {
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var sqlManager: SQLManager
    
    @Binding var sidebarVisibility: NavigationSplitViewVisibility
    @Binding var isFileDialogOpen: Bool
    @Binding var isSimulatorsDialogOpen: Bool
    
    @State private var error: SQLiteError? = nil
    @State private var showAlert = false
    
    var body: some View {
        HStack(spacing: 5) {
            Menu {
                Button("Open File…") { self.isFileDialogOpen.toggle() }
                Button("Browse Simulators…") { self.isSimulatorsDialogOpen.toggle() }
            } label: {
                HStack {
                    if let appInfo = self.sqlManager.openAppInfo {
                        if let appIcon = self.sqlManager.openAppInfo?.icon {
                            Label {
                                Text("App Options")
                            } icon: {
                                Image(nsImage: appIcon)
                            }
                        }
                        
                        Text(appInfo.name)
                    } else if let fileURL = self.sqlManager.openFileURL {
                        Label {
                            Text("Foder Options")
                        } icon: {
                            Image(systemName: "folder")
                        }
                        
                        Text(fileURL.deletingLastPathComponent().lastPathComponent)
                    }
                }
                .padding(5)
            }
            .menuIndicator(.hidden)
            
            if let fileURL = self.sqlManager.openFileURL {
                Image(systemName: "chevron.forward")
                
                if self.sqlManager.openAppInfo?.fileURLs.count ?? 0 > 1 {
                    Menu {
                        if let fileURLs = self.sqlManager.openAppInfo?.fileURLs {
                            ForEach(fileURLs, id: \.self) { fileURL in
                                if fileURL != self.sqlManager.openFileURL {
                                    Button(fileURL.lastPathComponent) {
                                        loadFile(from: fileURL)
                                    }
                                }
                            }
                        }
                    } label: {
                        fileView(fileURL.lastPathComponent)
                    }
                    .menuIndicator(.hidden)
                } else {
                    fileView(fileURL.lastPathComponent)
                }
            }
        }
        .fileImporter(
            isPresented: $isFileDialogOpen,
            allowedContentTypes: URL.sqlLiteContentTypes,
            onCompletion: loadFile
        )
        .sheet(isPresented: $isSimulatorsDialogOpen, content: {
            SimulatorsView(sidebarVisibility: $sidebarVisibility)
                .frame(width:800, height: 600)
        })
        .alert(isPresented: $showAlert, error: error) { _ in
            Button("OK") {
                self.showAlert = false
            }
        } message: { error in
            Text(error.recoverySuggestion ?? "Try opening a different file")
        }
    }
    
    @ViewBuilder
    private func fileView(_ fileName: String) -> some View {
        Image(systemName: "square.stack.3d.up")
        Text(fileName)
    }
    
    private func loadFile(from fileURL: URL) {
        Task(priority: .userInitiated) {
            if let homeBookmark = UserDefaults.standard.data(forKey: "homeBookmark") {
                var isHomeBookmarkInvalid = false
                
                let homeURL = try URL(
                    resolvingBookmarkData: homeBookmark,
                    options: .withSecurityScope,
                    bookmarkDataIsStale: &isHomeBookmarkInvalid
                )
                
                if !isHomeBookmarkInvalid, homeURL.startAccessingSecurityScopedResource() {
                    do {
                        try await self.sqlManager.connect(
                            fileURL: fileURL,
                            appInfo: self.sqlManager.openAppInfo
                        )
                    } catch let error as SQLiteError {
                        self.error = error
                        self.showAlert = true
                    }
                    
                    homeURL.stopAccessingSecurityScopedResource()
                }
            }
        }
    }
    
    private func loadFile(result: Result<URL, any Error>) {
        switch result {
        case .success(let fileURL):
            Task(priority: .userInitiated)  {
                do {
                    if fileURL.startAccessingSecurityScopedResource() {
                        try await self.sqlManager.connect(fileURL: fileURL)
                        
                        self.sidebarVisibility = .all
                        
                        fileURL.stopAccessingSecurityScopedResource()
                    }
                } catch let error as SQLiteError {
                    self.error = error
                    self.showAlert = true
                }
            }
        case .failure(let error):
            print(error.localizedDescription)
        }
    }
}
