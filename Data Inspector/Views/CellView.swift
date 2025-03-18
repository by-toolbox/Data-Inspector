//
//  CellView.swift
//  Data Inspector
//
//  Created by Axel Martinez on 13/3/25.
//

import SwiftUI

struct CellView: View {
    var id: UUID
    var property: String
    var type: Any.Type
    var updateProperty: (UUID, String, Any) -> Void
    
    @State var text: String
    
    init(id: UUID, property: String, value: Any, updateProperty: @escaping (UUID, String, Any) -> Void) {
        self.id = id
        self.property = property
        self.type = Swift.type(of: value)
        self.updateProperty = updateProperty
        
        switch value {
        case let string as String:
            self._text = State(initialValue: string)
        case let int as Int:
            self._text = State(initialValue: int.description)
        default:
            self._text = State(initialValue: "")
        }
    }
    
    var body: some View {
        TextField("", text: $text, onCommit: {
            switch type {
            case is Int.Type:
                if let int = Int(text) {
                    updateProperty(id, property, int)
                }
            default:
                updateProperty(id, property, text)
            }
        })
        .padding(.vertical, 5)
    }
}
