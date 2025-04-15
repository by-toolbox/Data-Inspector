//
//  Table.swift
//  Data Inspector
//
//  Created by Axel Martinez on 11/3/25.
//

class SQLiteTable: Decodable, Equatable, Hashable {
    var name: String
    var columns: [String: SQLiteColumn]
    var recordCount: Int

    init(name: String, columns: [String: SQLiteColumn], recordCount: Int) {
        self.name = name
        self.recordCount = recordCount
        self.columns = columns
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(columns)
    }
    
    static func == (lhs: SQLiteTable, rhs: SQLiteTable) -> Bool {
        lhs.name == rhs.name
    }
}
