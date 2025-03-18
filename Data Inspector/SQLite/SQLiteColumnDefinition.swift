//
//  SQLiteColumn.swift
//  Data Inspector
//
//  Created by Axel Martinez on 13/3/25.
//

import SQLiteKit

struct SQLiteColumnDefinition: Decodable, Equatable, Hashable {
    let name: String
    let type: SQLiteDataType
    let notNull: Bool
    let pk: Int
}
