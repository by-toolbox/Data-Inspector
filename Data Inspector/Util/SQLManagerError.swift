//
//  SQLManagerError.swift
//  Data Inspector
//
//  Created by Axel Martinez on 19/11/24.
//

enum SQLManagerError: Error {
    case noConnection(message: String)
    case invalidStatement
    case invalidResultSet
}
