//
//  SQLManager+Fetch.swift
//  Data Inspector
//
//  Created by Axel Martinez on 6/3/25.
//

import Foundation
import SQLiteKit

extension SQLManager {
    func getModels() async throws -> [Model] {
        let query = """
                    SELECT Z_NAME FROM Z_PRIMARYKEY
                    ORDER BY Z_NAME;
                    """
        
        let tableNames = try await runQuery(query) { row in
            try row.decode(column: "Z_NAME", as: String.self)
        }
        
        var models: [Model] = []
        
        for tableName in tableNames {
            if !SystemTables.allCases.contains(where: { $0.rawValue == tableName }) {
                models.append(try await getModel(tableName))
            }
        }
        
        return models
    }
    
    func getEntities() async throws -> [Entity] {
        let query = """
                    SELECT Z_NAME FROM Z_PRIMARYKEY
                    ORDER BY Z_NAME;
                    """
        
        let tableNames = try await runQuery(query) { row in
            try row.decode(column: "Z_NAME", as: String.self)
        }
        
        var entities: [Entity] = []
        
        for tableName in tableNames {
            if !SystemTables.allCases.contains(where: { $0.rawValue == tableName }) {
                entities.append(try await getEntity(tableName))
            }
        }
        
        return entities
    }
    
    func getTables() async throws -> [SQLiteTable] {
        let query = """
                    SELECT name FROM sqlite_master
                    WHERE type='table'
                    AND name NOT LIKE 'sqlite_%'
                    ORDER BY name;
                    """
        
        let tableNames = try await runQuery(query) { row in
            try row.decode(column: "name", as: String.self)
        }
        
        var tables: [SQLiteTable] = []
        
        for tableName in tableNames {
            tables.append(try await getTable(tableName))
        }
        
        return tables
    }
    
    func getModelRecords(from model: Model) async throws -> [Record] {
        let query = "SELECT ROWID as rowId,* FROM \(model.tableName)"
        let records = try await runQuery(query, mapping: { row in
            var values: Dictionary<String, Any> = [:]
            let rowId = try? row.decode(column: "rowId", as: Int.self)
            
            for column in model.columns {
                if let description = model.columns[column.key] {
                    mapValues(
                        columnName: description.name,
                        type: description.type,
                        row: row,
                        values: &values
                    )
                }
            }
            
            return Record(id: UUID(), rowId: rowId, values: values)
        })
        
        return records
    }
    
    func getEntityRecords(from entity: Entity) async throws -> [Record] {
        let query = "SELECT ROWID as rowId,* FROM \(entity.tableName)"
        let records = try await runQuery(query, mapping: { row in
            var values: Dictionary<String, Any> = [:]
            let rowId = try? row.decode(column: "rowId", as: Int.self)
            
            for column in entity.columns {
                if let description = entity.columns[column.key] {
                    mapValues(
                        columnName: description.name,
                        type: description.type,
                        row: row,
                        values: &values
                    )
                }
            }
            
            return Record(id: UUID(), rowId: rowId, values: values)
        })
        
        return records
    }
    
    func getTableRecords(from table: SQLiteTable) async throws -> [Record] {
        let query = "SELECT ROWID as rowId,* FROM \(table.tableName)"
        let records = try await runQuery(query, mapping: { row in
            var values: Dictionary<String, Any> = [:]
            let rowId = try? row.decode(column: "rowId", as: Int.self)
            
            for column in table.columns {
                if let description = table.columns[column.key] {
                    mapValues(
                        columnName: description.name,
                        type: description.type,
                        row: row,
                        values: &values
                    )
                }
            }
            
            return Record(id: UUID(), rowId: rowId, values: values)
        })
        
        return records
    }
    
    private func mapValues(
        columnName: String,
        type: SQLiteDataType,
        row: SQLRow,
        values: inout Dictionary<String, Any>
    ) {
        switch type {
        case .smallint:
            if let value = try? row.decode(column: columnName, as: Int16.self) {
                values[columnName] = value
            }
            break
        case .int:
            if let value = try? row.decode(column: columnName, as: Int.self) {
                values[columnName] = value
            }
            break
        case .float:
            if let value = try? row.decode(column: columnName, as: Float.self) {
                values[columnName] = value
            }
            break
        case .real:
            if let value = try? row.decode(column: columnName, as: Decimal.self) {
                values[columnName] = value
            }
            break
        case .text:
            if let value = try? row.decode(column: columnName, as: String.self) {
                values[columnName] = value
            }
            break
        case .blob:
            if let value = try? row.decode(column: columnName, as: ByteBuffer.self) {
                values[columnName] = value
            }
            break
        default:
            break
        }
    }
    
    private func getModel(_ name: String) async throws -> Model {
        let tableName = "Z\(name.uppercased())"
        let columns = try await columns(tableName)
        let recordCount = try await getRecordCount(tableName)
        let properties = columns.compactMap({ column -> Property? in
            if SystemColumns.allCases.contains(where: { $0.rawValue == column.key }) {
                return nil
            }
            
            var propertyName = column.key
            propertyName.removeFirst()
            
            return Property(name: propertyName.lowercased(), columnName: column.key)
        })
        
        return Model(
            name: name,
            properties: properties,
            tableName: tableName,
            columns: columns,
            recordCount: recordCount
        )
    }
    
    private func getEntity(_ name: String) async throws -> Entity {
        let tableName = "Z\(name.uppercased())"
        let columns = try await columns(tableName)
        let recordCount = try await getRecordCount(tableName)
        let properties = columns.compactMap({ column -> Property? in
            if SystemColumns.allCases.contains(where: { $0.rawValue == column.key }) {
                return nil
            }
            
            var propertyName = column.key
            propertyName.removeFirst()
            
            return Property(name: propertyName.lowercased(), columnName: column.key)
        })
        
        return Entity(
            name: name,
            properties: properties,
            tableName: tableName,
            columns: columns,
            recordCount: recordCount
        )
    }
    
    private func getTable(_ name: String) async throws -> SQLiteTable {
        let tableName = name
        let columns = try await columns(tableName)
        let recordCount = try await getRecordCount(tableName)
        
        return SQLiteTable(
            tableName: tableName,
            columns: columns,
            recordCount: recordCount
        )
    }
    
    private func columns(_ tableName: String) async throws -> [String: SQLiteColumnDefinition] {
        let query = "PRAGMA table_info(\(tableName));"
        
        return try await self.runQuery(query, handler: { rows in
            var result: Dictionary<String, SQLiteColumnDefinition> = [:]

            for row in rows {
                do  {
                    let columnName = try row.decode(column: "name", as: String.self)
                    let columnType = try row.decode(column: "type", as: SQLiteDataType.self)
                    let notNull = try row.decode(column: "notnull", as: Bool.self)
                    let pk = try row.decode(column: "pk", as: Int.self)
                    
                    result[columnName] = SQLiteColumnDefinition(
                        name: columnName,
                        type: columnType,
                        notNull: notNull,
                        pk: pk
                    )
                } catch {
                    print("Can't decode table \(tableName): \(error.localizedDescription)")
                }
            }
            
            return result
        })
    }
    
    private func getRecordCount(_ tableName: String) async throws -> Int {
        let query = "SELECT COUNT(*) as rowCount FROM \(tableName)"
        
        return try await runQuery(query, column: "rowCount") ?? 0
    }
}
