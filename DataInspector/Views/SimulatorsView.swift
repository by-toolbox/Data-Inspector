//
//  SimulatorsView.swift
//  Data Inspector
//
//  Created by Axel Martinez on 21/11/24.
//

import SwiftUI

struct SimulatorsView: View {
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var sqlManager: SQLManager
    @EnvironmentObject var simManager: SimulatorManager
    
    @Binding var sidebarVisibility: NavigationSplitViewVisibility
    
    @State private var isHomeBookmarkInvalid = false
    @State private var isFolderDialogOpen = false
    @State private var simulators = [Simulator]()
    @State private var homeURL: URL?
    @State private var selectedSimulatorURL: URL?
    @State private var selectedFileInfo: FileInfo?
    
    var userDirectory: URL? {
        if let userDirectory = FileManager.default.urls(for: .userDirectory, in: .localDomainMask).first {
            return userDirectory.appendingPathComponent(NSUserName())
        }
        
        return nil
    }
    
    var groupedSimulators: [(key: String, value: [Array<Simulator>.Element])] {
        Dictionary(grouping: simulators, by: { $0.runtime }).sorted(by: { $0.key > $1.key })
    }
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedSimulatorURL) {
                HStack {
                    Spacer()
                    
                    Text("Simulators")
                        .font(.title2)
                    
                    Spacer()
                }
                
                ForEach(groupedSimulators, id: \.key) { runtime, simSet in
                    Section(header: Text(runtime)) {
                        ForEach(simSet) { simulator in
                            Text(simulator.name)
                                .tag(simulator.url)
                        }
                    }
                }
            }
        } detail: {
            if let selectedSimulatorURL {
                SimulatorFilesView(
                    selectedFileInfo: $selectedFileInfo,
                    openFile: openFile,
                    simulatorURL: selectedSimulatorURL
                )
            } else {
                ContentUnavailableView("Select a simulator", systemImage: "macbook.and.iphone")
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { self.dismiss() }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Open") {
                    if let selectedFileInfo {
                        Task(priority: .userInitiated) {
                            try? await self.openFile(fileInfo: selectedFileInfo)
                        }
                    }
                }
                .disabled(self.selectedFileInfo == nil)
            }
        }
        .fileImporter(
            isPresented: $isFolderDialogOpen,
            allowedContentTypes: [.folder],
            onCompletion: { folder in
                switch folder {
                case .success(let folderPath):
                    if folderPath.startAccessingSecurityScopedResource() {
                        do {
                            let bookmark = try folderPath.bookmarkData(options: .withSecurityScope)
                            let homeURL = try URL(
                                resolvingBookmarkData: bookmark,
                                options: .withSecurityScope,
                                bookmarkDataIsStale: &isHomeBookmarkInvalid
                            )
                            
                            UserDefaults.standard.set(bookmark, forKey: "homeBookmark")
                            
                            self.simulators = simManager.loadSimulators(from: homeURL)
                        } catch {
                            print("Error saving home folder bookmark.")
                        }
                        
                        folderPath.stopAccessingSecurityScopedResource()
                    }
                case .failure(let error):
                    fatalError(error.localizedDescription)
                }
            }
        )
        .fileDialogConfirmationLabel("Grant Access")
        .fileDialogMessage("Allow access to your home directory to load simulators")
        .fileDialogDefaultDirectory(userDirectory)
        .onAppear {
            do {
                if let homeBookmark = UserDefaults.standard.data(forKey: "homeBookmark") {
                    self.homeURL = try URL(
                        resolvingBookmarkData: homeBookmark,
                        options: .withSecurityScope,
                        bookmarkDataIsStale: &isHomeBookmarkInvalid
                    )
                    
                    if let homeURL, homeURL.startAccessingSecurityScopedResource() {
                        if isHomeBookmarkInvalid {
                            self.isFolderDialogOpen.toggle()
                        } else {
                            self.simulators = self.simManager.loadSimulators(from: homeURL)
                            self.sidebarVisibility = .all
                        }
                    }
                } else {
                    self.isFolderDialogOpen.toggle()
                }
            } catch {
                print("Error loading home bookmark")
            }
        }
        .onDisappear {
            if let homeURL {
                homeURL.stopAccessingSecurityScopedResource()
            }
        }
    }
    
    func openFile(fileInfo: FileInfo) async throws {
        try await self.sqlManager.connect(fileURL: fileInfo.url, appInfo: fileInfo.appInfo)
        
        self.dismiss()
    }
}
