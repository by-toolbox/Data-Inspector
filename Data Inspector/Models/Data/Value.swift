//
//  DataType.swift
//  Data Inspector
//
//  Created by Axel Martinez on 13/3/25.
//

import Foundation

public enum PropertyType {
    case smallint(Int16)
    case integer(Int)
    case float(Float)
    case real(Double)
    case text(String)
    case blob(ByteBuffer)
    case null
    case timestamp(Date)
}

extension PropertyType: Decodable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let stringValue = try container.decode(String.self)
        let trimmedValue: String
        
        if let range = stringValue.range(of: "(") {
            trimmedValue = String(stringValue[..<range.lowerBound])
        } else {
            trimmedValue = stringValue
        }

        switch trimmedValue {
        case "SMALLINT":
            self = .smallint
        case "INTEGER":
            self = .integer
        case "BIGINT", "FLOAT":
            self = .float
        case "TEXT", "VARCHAR", "NVARCHAR":
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
