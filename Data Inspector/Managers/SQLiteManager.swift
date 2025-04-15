//
//  SQLManager.swift
//  Data Inspector
//
//  Created by Axel Martinez on 13/11/24.
//

import SQLiteKit
import SwiftUI

enum SQLiteManagerError: LocalizedError {
    case noConnection(message: String)
}

enum DisplayMode: String {
    case CoreData
    case SwiftData
    case SQLite
}

enum SystemTables: String, CaseIterable {
    case CHANGE
    case TRANSACTION
    case TRANSACTIONSTRING
}

enum SystemColumns: String, CaseIterable {
    case Z_PK
    case Z_ENT
    case Z_OPT
}

class SQLiteManager: ObservableObject {
    @Published var openFileURL: URL?
    @Published var openAppInfo: AppInfo?
    @Published var openAsSQLite = false
    @Published var displayMode: DisplayMode = .SQLite
    
    var connection: SQLiteConnection? = nil
    var db: any SQLDatabase {
        get throws {
            if let connection = connection, !connection.isClosed {
                return connection.sql()
            }
            
            throw SQLiteManagerError.noConnection(message: "No database connection available")
        }
    }
    
    deinit {
        try? self.closeConnection()
    }
    
    func connect(fileURL: URL, appInfo: AppInfo? = nil) async throws {
        if self.connection != nil {
            try closeConnection()
        }
        
        self.connection = try await SQLiteConnectionSource(
            configuration: .init(
                storage: .file(path: fileURL.absoluteString)
            ),
            threadPool: .singleton
        ).makeConnection(
            logger: .init(label: "DataInspector"),
            on: MultiThreadedEventLoopGroup.singleton.any()
        ).get()
        
        try await setDisplayMode()
        
        await MainActor.run {
            self.openFileURL = fileURL
            self.openAppInfo = appInfo
        }
    }
    
    func closeConnection() throws {
        try self.connection?.close().wait()
    }
    
    func runQuery(_ query: String) async throws {
        try await db.execute(sql: SQLQueryString(query)) { row in }
    }
    
    func runQuery<T>(_ query: String) async throws -> [T] where T: Decodable {
        let rows = try db.raw(SQLQueryString(query))
        
        return try await rows.all(decoding: T.self)
    }
    
    func runQuery<T>(_ query: String, mapping: (any SQLRow) throws -> T) async throws -> [T]  {
        let rows = try db.raw(SQLQueryString(query))
        
        return try await rows.all().map(mapping)
    }
    
    func runQuery<T>(_ query: String, column: String) async throws -> T? where T: Decodable {
        let row = try await db.raw(SQLQueryString(query)).first()
        
        return try row?.decode(column: column, as: T.self)
    }
    
    func runQuery(_ query: String, handler: @escaping @Sendable (any SQLRow) -> Void) async throws {
        let rows = try db.raw(SQLQueryString(query))
        
        try await rows.run(handler)
    }
    
    func runQuery<T>(_ query: String, handler: @escaping @Sendable ([any SQLRow]) -> T) async throws -> T {
        let rows = try db.raw(SQLQueryString(query))
        
        return try await handler(rows.all())
    }
    
    private func setDisplayMode() async throws {
        if openAsSQLite {
            await MainActor.run {
                self.displayMode = .SQLite
            }
        } else {
            let query = """
                        SELECT COUNT(*) as rowCount 
                        FROM sqlite_master 
                        WHERE type='table' AND name='Z_PRIMARYKEY'
                        """
            let count = try await runQuery(query, column: "rowCount") ?? 0
            if count > 0 {
                let tableNames = try await runQuery("SELECT Z_NAME FROM Z_PRIMARYKEY") { row in
                    try row.decode(column: "Z_NAME", as: String.self)
                }
                
                await MainActor.run {
                    if SystemTables.allCases.contains(where: { tableNames.contains($0.rawValue) }) {
                        self.displayMode = .SwiftData
                    } else {
                        self.displayMode = .CoreData
                    }
                }
            } else {
                await MainActor.run {
                    self.displayMode = .SQLite
                }
            }
        }
    }
}
