//
//  SQLManager+Edit.swift
//  Data Inspector
//
//  Created by Axel Martinez on 6/3/25.
//

extension SQLManager {
    func addRecord(_ record: Record,to table: SQLiteTable) async throws {
        // Prepare SQL query
        let properties = table.columns.map { $0.key }
        
        // Build insert query
        let columns = properties.joined(separator: ", ")
        let values = record.values.compactMap { $0.value as? String }.joined(separator: ", ")
        
        let query = "INSERT INTO \(table.tableName) (\(columns)) VALUES (\(values))"
        
        // Execute query
        try await runQuery(query)
    }
    
    func removeRecords(_ records: [Record],from table: SQLiteTable) async throws {
        var statements: [String] = []
        
        for record in records {
            statements.append(buildWhereClause(for: record, in: table))
        }
        
        let whereClause = statements.joined(separator: " OR ")
        
        // Prepare SQL query
        let query = "DELETE FROM \(table.tableName) WHERE \(whereClause)"
        
        // Execute query
        try await runQuery(query)
    }
    
    func updateProperty(
        _ property: Property,
        on record: Record,
        from table: SQLiteTable
    ) async throws {
        // Get right column
        guard let column = table.columns[property.columnName] else {
            return
        }
        
        let setClause = buildSetClause(for: [column], in: record)
        let whereClause = buildWhereClause(for: record, in: table)
        let query = "UPDATE \(table.tableName) SET \(setClause) WHERE \(whereClause)"
        
        // Execute query
        try await runQuery(query)
    }
    
    func updateRecord(_ record: Record, from table: SQLiteTable) async throws {
        let columns = table.columns.map { $0.value }
        let setClause = buildSetClause(for: columns, in: record)
        let whereClause = buildWhereClause(for: record, in: table)
        let query = "UPDATE \(table.tableName) SET \(setClause) WHERE \(whereClause)"
        
        try await runQuery(query)
    }
    
    private func buildSetClause(for columns: [SQLiteColumnDefinition], in record: Record) -> String {
        let columns = columns.filter {
            $0.datatype == .text || $0.datatype == .integer
        }
        
        return columns.compactMap {
            switch $0.storageClass {
            case .text:
                guard let value = record.values[$0.name] as? String else { return "" }
                return "\($0.name) = '\(value)'"
            case .integer:
                guard let value = record.values[$0.name] as? Int else { return "" }
                return "\($0.name) = \(value)"
            default:
                return nil
            }
        }.joined(separator: ",")
    }
    
    private func buildWhereClause(for record: Record, in table: SQLiteTable) -> String {
        var whereClause = table.columns.filter { $0.value.pk > 0 }.compactMap {
            if let value = record.values[$0.key] {
                return "\($0.key) = \(value)"
            }
            return nil
        }.joined(separator: ",")
        
        if whereClause.isEmpty {
            if let rowId = record.rowId {
                whereClause = "rowid = \(rowId)"
            } else {
                fatalError("Missing pk or rowId")
            }
        }
        
        return whereClause
    }
}
