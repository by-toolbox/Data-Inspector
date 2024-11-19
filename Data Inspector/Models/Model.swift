//
//  Model.swift
//  Data Inspector
//
//  Created by Axel Martinez on 14/11/24.
//

struct Model: Codable, Hashable {
    let name: String
    let columns: [String]
    let records: [Record]
}
