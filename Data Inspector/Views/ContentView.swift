//
//  Content.swift
//  Data Inspector
//
//  Created by Axel Martinez on 13/11/24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var manager: SQLManager
    
    @State private var model: Model?
    @State private var isLoading = false
    @State private var selectedRecords = Set<UUID>()
    
    var entity: Entity
    
    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                ProgressView()
            } else if let model = model, model.records.count > 0 {
                Divider()
                
                Table(model.records, selection: $selectedRecords) {
                    TableColumnForEach(model.columns, id:\.self) { column in
                        TableColumn(column) { record in
                            if let value = record.values[column] {
                                Text(value)
                            }
                        }
                    }
                }
                .background(Color.white)
            } else {
                ContentUnavailableView("No records to show", systemImage: "tray.fill")
            }
        }
        .onChange(of: entity) { _,newValue in
            self.isLoading = true
            
            Task(priority: .userInitiated) {
                do {
                    self.model = try await self.manager.getModel(newValue.name)
                    self.isLoading = false
                } catch {
                    fatalError(error.localizedDescription)
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var isInspectorOpen = false
    @Previewable @State var isFileDialogOpen = false
    
    ContentView(entity: Entity(name: "", rowCount: 0))
}
