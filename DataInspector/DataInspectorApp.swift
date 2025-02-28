//
//  DataInspectorApp.swift
//  Data Inspector
//
//  Created by Axel Martinez on 12/12/24.
//

import SwiftUI

@main
struct DataInspectorApp: App {
    @State var isFileDialogOpen = false
    @State var isSimulatorsDialogOpen = false
    
    var body: some Scene {
        WindowGroup {
            MainView(
                isFileDialogOpen: $isFileDialogOpen,
                isSimulatorsDialogOpen: $isSimulatorsDialogOpen
            )
            .onAppear {
                NSWindow.allowsAutomaticWindowTabbing = false
            }
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open file...") { self.isFileDialogOpen.toggle() }
                Button("Browse Simulators...") { self.isSimulatorsDialogOpen.toggle() }
            }
        }
    }
}
