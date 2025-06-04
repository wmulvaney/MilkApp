import Foundation
import SwiftUI

struct StoredRecipe: Identifiable, Codable {
    let id: UUID
    var recipe: Recipe
    var quantity: Int
    
    init(recipe: Recipe, quantity: Int = 1) {
        self.id = UUID()
        self.recipe = recipe
        self.quantity = quantity
    }
}
