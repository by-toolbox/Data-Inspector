//
//  Content.swift
//  Data Inspector
//
//  Created by Axel Martinez on 13/11/24.
//

import Combine
import SQLiteKit
import SwiftUI

struct ContentView<T: SQLiteTable>: View {
    @EnvironmentObject var sqlManager: SQLManager
    
    @Binding var searchText: String
    
    @State private var isLoading = false
    @State private var selectedRecords = Set<UUID>()
    @State private var properties = [Property]()
    @State private var records = [Record]()
    @State private var error: SQLiteError? = nil
    @State private var showAlert = false
    
    var dataObject: T
    var refreshRecords: PassthroughSubject<Void, Never>
    
    var filteredRecords: [Record] {
        return records.filter({ record in
            self.searchText.isEmpty || record.values.contains(where: {
                if let value = $0.value as? String {
                    return value.contains(self.searchText)
                }
                
                return false
            })
        })
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                ProgressView()
            } else {
                if records.isEmpty {
                    ContentUnavailableView("No records to show", image: "table.xmark")
                } else {
                    HStack(alignment: .center, spacing: 10) {
                        Spacer()
                        
                        Button(action: {}, label: {
                            Image(systemName: "plus")
                        })
                        .disabled(true)
                        .buttonStyle(.link)
                        
                        Button(action: removeRecords, label: {
                            Image(systemName: "trash")
                        })
                        .buttonStyle(.link)
                        .disabled(selectedRecords.isEmpty)
                        
                        Button(action: removeRecords, label: {
                            Image(systemName: "info")
                        })
                        .disabled(true)
                        .buttonStyle(.link)
                        
                        Spacer()
                    }
                    .font(.headline)
                    .padding(.vertical)
                    .background(.white)
                    
                    Table(filteredRecords, selection: $selectedRecords) {
                        TableColumnForEach(properties, id:\.self) { property in
                            TableColumn(
                                Text(property.name)
                                    .font(.headline)
                                    .foregroundStyle(.blue)
                            ) { record in
                                if let value = record.values[property.columnName] {
                                    CellView(
                                        id: record.id,
                                        property: property.name,
                                        value: value,
                                        updateProperty: updateProperty
                                    )
                                  
                                }
                            }
                        }
                    }
                    .alternatingRowBackgrounds(.disabled)
                    .onKeyPress { event in
                        switch event.key {
                        case "\u{7f}", .delete:
                            removeRecords()
                            return .handled
                        default:
                            return .ignored
                        }
                    }
                }
            }
        }
        .onAppear(perform: refresh)
        .onChange(of: dataObject, refresh)
        .onReceive(refreshRecords, perform: refresh) .alert(isPresented: $showAlert, error: error) { _ in
            Button("OK") {
                self.showAlert = false
            }
        } message: { error in
            Text(error.recoverySuggestion ?? "Try opening a different file")
        }
    }
    
    func refresh() {
        Task(priority: .userInitiated) {
            do {
                self.isLoading = true
                
                if let model = dataObject as? Model {
                    self.records = try await sqlManager.getModelRecords(from: model)
                    self.properties = model.properties.sorted { $0.name < $1.name }
                } else if let entity = dataObject as? Entity {
                    self.records = try await sqlManager.getEntityRecords(from: entity)
                    self.properties = entity.properties.sorted { $0.name < $1.name }
                } else {
                    self.records = try await sqlManager.getTableRecords(from: dataObject)
                    self.properties = dataObject.columns.map {
                        Property(name: $0.key, columnName: $0.key)
                    }.sorted { $0.name < $1.name }
                }
                
                self.isLoading = false
            } catch let error as SQLiteError{
                self.error = error
                self.showAlert = true
            }
        }
    }
    
    func removeRecords() {
        if selectedRecords.isEmpty { return }
        
        Task(priority: .userInitiated) {
            do {
                let recordsToRemove = records.filter { selectedRecords.contains($0.id) }
                
                // Remove records from the database
                try await sqlManager.removeRecords(recordsToRemove, from: dataObject)
                
                await MainActor.run {
                    // Remove the records from the local array
                    records.removeAll { selectedRecords.contains($0.id) }
                    
                    // Clear selection
                    selectedRecords.removeAll()
                }
            } catch let error as SQLiteError {
                self.error = error
                self.showAlert = true
            }
        }
    }
    
    func updateProperty(from id: UUID, propertyName: String, to newValue: Any) {
        // Find the index of the current record
        if var record = records.first(where: { $0.id == id }),
           let property = properties.first(where: { $0.name == propertyName }){
            Task {
                // Update the value the fetched record
                record.values[property.columnName] = newValue
                
                // Update in database
                do {
                    try await sqlManager.updateProperty(
                        property,
                        on: record,
                        from: dataObject
                    )
                } catch let error as SQLiteError {
                    self.error = error
                    self.showAlert = true
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var searchText: String = ""
    @Previewable @State var refreshRecords: PassthroughSubject<Void, Never> = .init()
    
    let table = SQLiteTable(tableName: "tst", columns: [:], recordCount: 0)
    
    ContentView(searchText: $searchText, dataObject: table, refreshRecords: refreshRecords)
}
