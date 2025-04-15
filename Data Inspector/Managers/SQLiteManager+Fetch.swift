//
//  SQLManager+Fetch.swift
//  Data Inspector
//
//  Created by Axel Martinez on 6/3/25.
//

import Foundation
import SQLiteKit
import SwiftData

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
    
    func getRecords(from model: Model) async throws -> [Record] {
        let query = "SELECT ROWID as rowId,* FROM \(model.tableName)"
        return try await runQuery(query, mapping: { row in
            return try Record(row, from: model)
        })
    }
    
    func getRecords(from entity: Entity) async throws -> [Record] {
        let query = "SELECT ROWID as rowId,* FROM \(entity.tableName)"
        return try await runQuery(query, mapping: { row in
            return try Record(row, from: entity)
        })
    }
    
    func getRecords(from table: SQLiteTable) async throws -> [Record] {
        let query = "SELECT ROWID as rowId,* FROM \(table.tableName)"
        return try await runQuery(query, mapping: { row in
            return try Record(row, from: table)
        })
    }
    
    private func getModel(_ name: String) async throws -> Model {
        let tableName = "Z\(name.uppercased())"
        let columns = try await getColumns(from: tableName)
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
        let columns = try await getColumns(from: tableName)
        let recordCount = try await getRecordCount(tableName)
        let properties = columns.compactMap({ column -> Property? in
            if SystemColumns.allCases.contains(where: { $0.rawValue == column.key }) {
                return nil
            }
            
            var propertyName = column.key
            propertyName.removeFirst()
            
            return Property(
                name: propertyName.lowercased(),
                columnName: column.key
            )
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
        let columns = try await getColumns(from: tableName)
        let recordCount = try await getRecordCount(tableName)
        
        return SQLiteTable(
            tableName: tableName,
            columns: columns,
            recordCount: recordCount
        )
    }
    
    private func getColumns(from tableName: String) async throws -> [String: SQLiteColumnDefinition] {
        let query = "PRAGMA table_info(\(tableName));"
        
        return try await self.runQuery(query, handler: { rows in
            var result: Dictionary<String, SQLiteColumnDefinition> = [:]

            for row in rows {
                do  {
                    let name = try row.decode(column: "name", as: String.self)
                    let dataType = try row.decode(column: "type", as: String.self)
                    let notNull = try row.decode(column: "notnull", as: Bool.self)
                    let pk = try row.decode(column: "pk", as: Int.self)
                    
                    result[name] = SQLiteColumnDefinition(
                        name: name,
                        datatype: dataType,
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
