//
//  Content.swift
//  Data Inspector
//
//  Created by Axel Martinez on 13/11/24.
//

import Combine
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var sqlManager: SQLManager
    
    @State private var model: Model?
    @State private var isLoading = false
    @State private var selectedRecords = Set<UUID>()
    
    @Binding var searchText: String
    
    var entity: Entity
    var refreshRecords: PassthroughSubject<Void, Never>
    
    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                ProgressView()
            } else if let model {
                let records = listRecords(from: model)
                
                if records.isEmpty {
                    ContentUnavailableView("No records to show", image: "table.xmark")
                } else {
                    Table(records, selection: $selectedRecords) {
                        TableColumnForEach(model.columns, id:\.self) { column in
                            TableColumn(column) { record in
                                if let value = record.values[column] {
                                    Text(value)
                                }
                            }
                        }
                    }
                    .background(Color.white)
                }
            }
        }
        .onAppear(perform: refresh)
        .onChange(of: entity, refresh)
        .onReceive(refreshRecords, perform: refresh)
    }
    
    func listRecords(from model: Model) -> [Record] {
        return model.records.filter({ record in
            self.searchText.isEmpty || record.values.contains(where: { $0.value.contains(self.searchText) })
        })
    }
    
    func refresh() {
        Task(priority: .userInitiated) {
            do {
                self.isLoading = true
                
                self.model = try await self.sqlManager.getModel(self.entity.name)
                
                self.isLoading = false
            } catch {
                fatalError(error.localizedDescription)
            }
        }
    }
}

#Preview {
    @Previewable @State var isInspectorOpen = false
    @Previewable @State var isFileDialogOpen = false
    @Previewable @State var searchText: String = ""
    @Previewable @State var refreshRecords: PassthroughSubject<Void, Never> = .init()
    
    ContentView(searchText: $searchText, entity: Entity(name: "", rowCount: 0), refreshRecords: refreshRecords)
}
