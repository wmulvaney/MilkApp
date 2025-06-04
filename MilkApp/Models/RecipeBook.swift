import Foundation

struct RecipeBook: Identifiable, Codable {
    let id: String
    let author: User
    let title: String
    let description: String
    let dateCreated: Date
    let coverImage: String?
    let recipes: [Recipe]
    
    enum CodingKeys: String, CodingKey {
        case id
        case author
        case title
        case description
        case dateCreated = "date_created"
        case coverImage = "cover_image"
        case recipes
    }
}