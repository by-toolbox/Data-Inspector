//
//  SQLiteColumn.swift
//  Data Inspector
//
//  Created by Axel Martinez on 13/3/25.
//

import SQLiteKit

struct SQLiteColumnDefinition: Codable {
    let name: String
    //let data: SQLiteData
    let notNull: Bool
    let pk: Int
    
    /*var description: String {
        "\(self.name): \(self.data)"
    }*/
}

/*extension SQLiteData: @retroactive Decodable {
    enum CodingKeys: String, CodingKey {
        case name
        case data
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let text = try? container.decode(String.self) {
            self = .text(text)
        } else if let integer = try? container.decode(Int.self) {
            self = .integer(integer)
        } else if let float = try? container.decode(Double.self) {
            self = .float(float)
        } else if let blob = try? container.decode(ByteBuffer.self) {
            self = .blob(blob)
        } else {
            self = .null
        }
    }
}

extension SQLiteData: @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .integer(let value): hasher.combine(value)
        case .float(let value): hasher.combine(value)
        case .text(let value): hasher.combine(value)
        case .blob(let value): hasher.combine(value)
        case .null: break
        }
    }
}*/
