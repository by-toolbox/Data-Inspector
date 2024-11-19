//
//  SQLManager.swift
//  Data Inspector
//
//  Created by Axel Martinez on 13/11/24.
//

import SQLKit
import SQLiteKit
import SwiftUI

class SQLManager: ObservableObject {
    @Published var filePath: URL?
    
    var connection: SQLiteConnection? = nil
    var db: any SQLDatabase {
        get throws {
            if let connection = connection {
                return connection.sql()
            }
            
            throw SQLManagerError.noConnection(message: "No database connection available")
        }
    }
    
    deinit {
        try? self.closeConnection()
    }
    
    func connect(filePath: URL) async throws {
        if self.connection != nil {
            try closeConnection()
        }
        
        self.connection = try await SQLiteConnectionSource(
            configuration: .init(
                storage: .file(path: filePath.absoluteString)
            ),
            threadPool: .singleton
        ).makeConnection(
            logger: .init(label: "test"),
            on: MultiThreadedEventLoopGroup.singleton.any()
        ).get()
        
        await MainActor.run {
            self.filePath = filePath
        }
    }
    
    func getModels() async throws -> [Entity] {
        let query = """
                    SELECT name FROM sqlite_master
                    WHERE type='table'
                    AND name NOT LIKE 'sqlite_%'
                    ORDER BY name;
                    """
        
        let tableNames = try await runQuery(query) { row in
            try row.decode(column: "name", as: String.self)
        }
        
        var entities = [Entity]()
        
        for tableName in tableNames {
            let entity = try await getEntity(tableName)
            entities.append(entity)
        }
        
        return entities
    }
    
    func getEntity(_ tableName: String) async throws -> Entity {
        let query = "SELECT COUNT(*) as rowCount FROM \(tableName)"
        
        do {
            let rowCount: Int = try await runQuery(query, column: "rowCount") ?? 0
            return Entity(name: tableName, rowCount: rowCount)
        } catch {
            print("Can't decode table \(tableName): \(error.localizedDescription)")
        }
        
        throw SQLManagerError.invalidResultSet
    }
    
    func getModel(_ tableName: String) async throws -> Model {
        let query = "SELECT * FROM \(tableName)"
        
        do {
            var columns: [String] = []
            
            let records = try await runQuery(query) { row in
                var values = Dictionary<String, String>()
                
                if columns.isEmpty {
                    columns = row.allColumns
                }
                
                for column in columns {
                    values[column] = try row.decode(column: column, as: String.self)
                }
                
                return Record(id: UUID(), values: values)
            }
            
            return Model(name: tableName, columns: columns, records: records)
        } catch {
            print("Can't decode table \(tableName): \(error.localizedDescription)")
        }
        
        return Model(name: tableName, columns: [], records: [])
    }
    
    private func closeConnection() throws {
        try self.connection?.close().wait()
    }
    
    private func runQuery<T>(_ query: String, mapping: ((any SQLRow) throws -> T)? = nil) async throws -> [T] where T: Decodable {
        let rows = try db.raw(SQLQueryString(query))
        
        if let mapping = mapping {
            return try await rows.all().map(mapping)
        } else {
            return try await rows.all(decoding: T.self)
        }
    }
    
    private func runQuery<T>(_ query: String, column: String) async throws -> T? where T: Decodable {
        let row = try await db.raw(SQLQueryString(query)).first()
    
        return try row?.decode(column: column, as: T.self)
    }
    
    private func runQuery(_ query: String, handler: @escaping @Sendable (any SQLRow) -> Void) async throws {
        let rows = try db.raw(SQLQueryString(query))
    
        try await rows.run(handler)
    }
}
