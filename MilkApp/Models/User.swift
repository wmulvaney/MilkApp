import Foundation

struct User: Identifiable, Codable {
    let id: String
    let name: String?
    let username: String
    let email: String
    var profileImage: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case username
        case email
        case profileImage = "profile_image"
    }
}