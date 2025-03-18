//
//  Table.swift
//  Data Inspector
//
//  Created by Axel Martinez on 11/3/25.
//

class SQLiteTable: Codable, Equatable {
    var tableName: String
    var recordCount: Int
    var columns: Dictionary<String, String>
    
    init(tableName: String, columns: Dictionary<String, String>, recordCount: Int) {
        self.tableName = tableName
        self.recordCount = recordCount
        self.columns = columns
    }
    
    static func == (lhs: SQLiteTable, rhs: SQLiteTable) -> Bool {
        lhs.tableName == rhs.tableName
    }
}
