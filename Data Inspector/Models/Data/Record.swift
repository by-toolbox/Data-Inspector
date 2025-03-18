//
//  Record.swift
//  Data Inspector
//
//  Created by Axel Martinez on 14/11/24.
//

import Foundation

struct Record: Identifiable, Equatable {
    var id: UUID
    var rowId: Int?
    var values: Dictionary<String, Any>
    
    static func == (lhs: Record, rhs: Record) -> Bool {
        lhs.id == rhs.id
    }
}

extension Record: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
