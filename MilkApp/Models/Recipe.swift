import Foundation
import SwiftUI

// MARK: - Structs
struct Recipe: Identifiable, Codable {
    let id: String
    let name: String
    let image: String
    let ingredients: [QuantifiedIngredient]
    let instructions: [String]
    let prepTime: Int // in minutes
    let cookTime: Int // in minutes
    let calories: Int
    let cuisine: String
    let servings: Int
    let description: String?
    let mealType: MealType
    let createdBy: User?

    enum CodingKeys: String, CodingKey {
        case id, name, ingredients, instructions, calories, cuisine, servings, description, image, createdBy
        case prepTime = "prepTime"
        case cookTime = "cookTime"
        case mealType = "mealType"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        let imageUrl = try container.decode(String.self, forKey: .image)
        image = imageUrl.isEmpty ? "https://firebasestorage.googleapis.com/v0/b/milk-39cd2.appspot.com/o/NO%20IMAGE%20FOUND.png?alt=media&token=236e6088-64cf-4e9f-a8f0-877468c743b7" : imageUrl
        ingredients = try container.decode([QuantifiedIngredient].self, forKey: .ingredients)
        instructions = try container.decode([String].self, forKey: .instructions)
        prepTime = try container.decode(Int.self, forKey: .prepTime)
        cookTime = try container.decode(Int.self, forKey: .cookTime)
        calories = try container.decode(Int.self, forKey: .calories)
        cuisine = try container.decode(String.self, forKey: .cuisine)
        servings = try container.decode(Int.self, forKey: .servings)
        description = try container.decode(String.self, forKey: .description)
        mealType = try container.decodeIfPresent(MealType.self, forKey: .mealType) ?? .unknown
        createdBy = try container.decode(User.self, forKey: .createdBy)
    }
}

extension Recipe {
    // Conform to Identifiable
    var idValue: String { id }
}

struct RecipeResponse: Codable {
    let success: Bool
    let recipes: [Recipe]

    enum CodingKeys: String, CodingKey {
        case success
        case recipes
    }
}

extension Recipe {
    init(id: String, name: String, image: String, ingredients: [QuantifiedIngredient], instructions: [String], prepTime: Int, cookTime: Int, calories: Int, cuisine: String, servings: Int, description: String, mealType: MealType, createdBy: User) {
        self.id = id
        self.name = name
        self.image = image
        self.ingredients = ingredients
        self.instructions = instructions
        self.prepTime = prepTime
        self.cookTime = cookTime
        self.calories = calories
        self.cuisine = cuisine
        self.servings = servings
        self.description = description
        self.mealType = mealType
        self.createdBy = createdBy
    }
}

// Add this enum after the Recipe struct
enum MealType: String, Codable {
    case dinner = "Dinner"
    case snack = "Snack"
    case lunch = "Lunch"
    case breakfast = "Breakfast"
    case dessert = "Dessert"
    case appetizer = "Appetizer"
    case entree = "Entree"
    case side = "Side"
    case drink = "Drink"
    case unknown = "Unknown"
    static let allCases = [dinner, snack, lunch, breakfast, dessert, appetizer, entree, side, drink, unknown]

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try? container.decode(String.self)
        self = MealType(rawValue: rawValue ?? "") ?? .unknown
    }
}
