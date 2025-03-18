//
//  SQLManager+CRUD.swift
//  Data Inspector
//
//  Created by Axel Martinez on 6/3/25.
//

extension SQLManager {
    func createModel(withName name: String, into tableName: String) async throws -> Entity {
        let query = """
                    CREATE TABLE \(tableName)
                    """
   
        var entities = [Entity]()
        
        for tableName in tableNames {
            let entity = try await getEntity(tableName)
            entities.append(entity)
        }
        
        return entity
    }
    
    func deleteModel(_ model: Entity) async throws {
        
    }
}
