//
//  Table.swift
//  Data Inspector
//
//  Created by Axel Martinez on 11/3/25.
//

class SQLiteTable: Decodable, Equatable, Hashable {
    var tableName: String
    var columns: Dictionary<String, SQLiteColumnDefinition>
    var recordCount: Int

    init(tableName: String, columns: Dictionary<String, SQLiteColumnDefinition>, recordCount: Int) {
        self.tableName = tableName
        self.recordCount = recordCount
        self.columns = columns
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(tableName)
        hasher.combine(columns)
    }
    
    static func == (lhs: SQLiteTable, rhs: SQLiteTable) -> Bool {
        lhs.tableName == rhs.tableName
    }
}
