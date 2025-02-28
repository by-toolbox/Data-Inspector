//
//  MainView.swift
//  Data Inspector
//
//  Created by Axel Martinez on 13/11/24.
//

import Combine
import SwiftUI

struct MainView: View {
    @StateObject var sqlManager: SQLManager = .init()
    @StateObject var simManager: SimulatorManager = .init()
    
    @Binding var isFileDialogOpen: Bool
    @Binding var isSimulatorsDialogOpen: Bool
    
    @State private var sidebarVisibility: NavigationSplitViewVisibility = .detailOnly
    @State private var selectedEntity: Entity?
    @State private var searchText: String = ""
    @State private var refreshRecords: PassthroughSubject<Void, Never> = .init()
    
    var body: some View {
        NavigationSplitView(columnVisibility: $sidebarVisibility) {
            SidebarView(selection: $selectedEntity)
                .environmentObject(sqlManager)
        } detail: {
            if let selectedEntity {
                ContentView(
                    searchText: $searchText,
                    entity: selectedEntity,
                    refreshRecords: refreshRecords
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .environmentObject(sqlManager)
                .environmentObject(simManager)
            } else if self.sqlManager.openFileURL != nil {
                ContentUnavailableView(
                    "Select a model",
                    image: "table.check",
                    description: Text("Select a model to view it's records.")
                )
            } else {
                ContentUnavailableView {
                    Label {
                        Text("Open database")
                    } icon: {
                        Image("database.search")
                    }
                } description: {
                    Text("Open a database to load it's entities.")
                } actions: {
                    Button("Open file...") { self.isFileDialogOpen.toggle() }
                    Button("Browse simulators...") { self.isSimulatorsDialogOpen.toggle() }
                }
            }
        }
        .navigationTitle("")
        .searchable(text: $searchText)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                FileMenu(
                    sidebarVisibility: $sidebarVisibility,
                    isFileDialogOpen: $isFileDialogOpen,
                    isSimulatorsDialogOpen: $isSimulatorsDialogOpen,
                    selectedEntity: $selectedEntity
                )
                .environmentObject(sqlManager)
                .environmentObject(simManager)
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button("", systemImage: "arrow.clockwise", action: {
                    refreshRecords.send()
                })
                .disabled(self.selectedEntity == nil)
            }
        }
    }
}

#Preview {
    @Previewable @State var isFileDialogOpen = false
    @Previewable  @State var isSimulatorsDialogOpen = false
    
    MainView(
        isFileDialogOpen: $isFileDialogOpen,
        isSimulatorsDialogOpen: $isSimulatorsDialogOpen
    )
}
