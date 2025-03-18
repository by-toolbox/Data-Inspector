//
//  SidebarView.swift
//  Data Inspector
//
//  Created by Axel Martinez on 13/11/24.
//

import SwiftUI
import SQLKit

struct SidebarView<T: SQLiteTable>: View {
    @EnvironmentObject var sqlManager: SQLManager
    
    @Binding var selection: T?
    
    @State private var dataObjects = [T]()
    
    var body: some View {
        VStack {
            List(selection: $selection) {
                switch(sqlManager.displayMode) {
                case .SwiftData:
                    if let models = dataObjects as? [Model] {
                        Section(header: Text("Models")) {
                            ForEach(models, id: \.self) { model in
                                HStack {
                                    Label(model.name, systemImage: "cube")
                                    Spacer()
                                    Text("\(model.recordCount)")
                                }
                            }
                        }
                    }
                case .CoreData:
                    if let entities = dataObjects as? [Entity] {
                        Section(header: Text("Entities")) {
                            ForEach(entities, id: \.self) { entity in
                                HStack {
                                    Label(entity.name, systemImage: "e.square")
                                    Spacer()
                                    Text("\(entity.recordCount)")
                                }
                            }
                        }
                    }
                default:
                    Section(header: Text("Tables")) {
                        ForEach(dataObjects, id: \.self) { dataObject in
                            HStack {
                                Label(dataObject.tableName, systemImage: "tablecells")
                                Spacer()
                                Text("\(dataObject.recordCount)")
                            }
                        }
                    }
                }
            }
            .listStyle(SidebarListStyle())
        }
        .onChange(of: self.sqlManager.openFileURL) { _,_ in
            Task(priority: .userInitiated) {
                do {
                    switch(sqlManager.displayMode) {
                    case .SwiftData:
                        self.dataObjects = try await self.sqlManager.getModels() as! [T]
                        break
                    case .CoreData:
                        self.dataObjects = try await self.sqlManager.getEntities() as! [T]
                        break
                    default:
                        self.dataObjects = try await self.sqlManager.getTables() as! [T]
                        break
                    }
                  
                    self.selection = self.dataObjects.first
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }
}

#Preview {
    @Previewable let manager = SQLManager()
    @Previewable @State var selection: Entity?
    
    SidebarView(selection: $selection).environmentObject(manager)
}
