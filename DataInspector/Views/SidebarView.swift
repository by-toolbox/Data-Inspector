//
//  SidebarView.swift
//  Data Inspector
//
//  Created by Axel Martinez on 13/11/24.
//

import SwiftUI
import SQLKit

struct SidebarView: View {
    @EnvironmentObject var sqlManager: SQLManager
    
    @Binding var selection: Entity?
    
    @State var entities = [Entity]()
    
    var body: some View {
        List(selection: self.$selection) {
            Section(header: Text("Models")) {
                ForEach(entities, id: \.self) { entity in
                    HStack {
                        Label(entity.name, systemImage: "tablecells")
                        Spacer()
                        Text("\(entity.rowCount)")
                    }
                }
            }
        }
        .listStyle(SidebarListStyle())
        .onChange(of: self.sqlManager.openFileURL) { _,_ in
            Task(priority: .userInitiated) {
                do {
                    self.entities = try await self.sqlManager.getModels()
                    self.selection = self.entities.first
                } catch {
                    fatalError(error.localizedDescription)
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
