//
//  Model.swift
//  Data Inspector
//
//  Created by Axel Martinez on 14/11/24.
//

class Model: SQLiteTable {
    let name: String
    let properties: [Property]
    
    init(
        name: String,
        properties: [Property] = [],
        tableName: String,
        columns: Dictionary<String, SQLiteColumnDefinition>,
        recordCount: Int = 0
    ) {
        self.name = name
        self.properties = properties
        
        super.init(tableName: tableName, columns: columns, recordCount: recordCount)
    }
    
    required init(from decoder: any Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}
