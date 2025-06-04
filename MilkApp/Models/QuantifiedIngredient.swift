import Foundation

enum Unit: String, Codable, CaseIterable {
    case pound = "lb"
    case fluidOunce = "fl oz"
    case ounce = "oz"
    case cup = "cup"
    case quart = "qt"
    case gallon = "gal"
    case pint = "pt"
    case teaspoon = "tsp"
    case tablespoon = "tbsp"
    case each = "each"
    case toTaste = "to taste"
    case milliliter = "ml"
    case gram = "g"
    case kilogram = "kg"
    case liter = "l"
    case unknown = ""
}

struct QuantifiedIngredient: Identifiable, Codable, Equatable, Hashable {
    let id: UUID = UUID()
    var name: String
    var quantity: Double
    var unit: Unit
    
    init(id: UUID = UUID(), name: String, quantity: Double, unit: Unit) {
        self.name = name
        self.quantity = quantity
        self.unit = unit
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension QuantifiedIngredient {
    var description: String {
        let formattedQuantity = String(format: "%.1f", quantity)
        return "\(formattedQuantity) \(unit.rawValue) \(name)"
    }
}
