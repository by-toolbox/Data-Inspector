//
//  SQLiteDataType.swift
//  Data Inspector
//
//  Created by Axel Martinez on 13/3/25.
//

public enum SQLiteDataType {
    case smallint
    case int
    case float
    case real
    case text
    case blob
    case null
    case timestamp
}

extension SQLiteDataType: Decodable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let stringValue = try container.decode(String.self)
        
        switch stringValue {
        case "SMALLINT":
            self = .smallint
        case "INTEGER":
            self = .int
        case "BIGINT", "FLOAT":
            self = .float
        case "TEXT", "VARCHAR":
            self = .text
        case "REAL":
            self = .real
        case "BLOB":
            self = .blob
        case "TIMESTAMP":
            self = .timestamp
        default:
            self = .null
        }
    }
}
