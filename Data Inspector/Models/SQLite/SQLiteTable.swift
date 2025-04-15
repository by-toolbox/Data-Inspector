//
//  SQLiteTable.swift
//  Data Inspector
//
//  Created by Axel Martinez on 11/3/25.
//

class SQLiteTableDescription: Decodable, Equatable, Hashable {
    var tableName: String
    var columns: [SQLiteColumnDescription]
    var recordCount: Int

    init(tableName: String, columns: [SQLiteColumnDescription], recordCount: Int) {
        self.tableName = tableName
        self.recordCount = recordCount
        self.columns = columns
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(tableName)
        hasher.combine(columns)
    }
    
    static func == (lhs: SQLiteTableDescription, rhs: SQLiteTableDescription) -> Bool {
        lhs.tableName == rhs.tableName
    }
}
