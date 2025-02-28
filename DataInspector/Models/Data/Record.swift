//
//  Record.swift
//  Data Inspector
//
//  Created by Axel Martinez on 14/11/24.
//

import Foundation

struct Record: Hashable, Codable, Identifiable {
    var id: UUID
    var values = Dictionary<String, String>()
}
