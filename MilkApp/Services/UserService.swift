import Foundation

class UserService {
    static let shared = UserService()
    private let baseURL = "http://127.0.0.1:8000"  // or your machine's IP address
    
    private init() {}
    
    func followUser(userId: String, completion: @escaping (Bool, String?) -> Void) {
        toggleFollowUser(userId: userId, following: true, completion: completion)
    }

    func unfollowUser(userId: String, completion: @escaping (Bool, String?) -> Void) {
        toggleFollowUser(userId: userId, following: false, completion: completion)
    }

    private func toggleFollowUser(userId: String, following: Bool, completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: "\(baseURL)/follow-user/") else {
            completion(false, "Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add the authentication token to the request header
        if let token = AuthenticationService.shared.authToken {
            request.setValue("Token \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body: [String: Any] = ["user_id": userId, "following": following]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(false, "Network error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                completion(false, "No data received")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let success = json["success"] as? Bool, success {
                        let action = following ? "followed" : "unfollowed"
                        let message = json["message"] as? String ?? "Successfully \(action) user"
                        completion(true, message)
                    } else {
                        let action = following ? "follow" : "unfollow"
                        let message = json["message"] as? String ?? "Failed to \(action) user"
                        completion(false, message)
                    }
                } else {
                    completion(false, "Invalid response format")
                }
            } catch {
                completion(false, "Error parsing response: \(error.localizedDescription)")
            }
        }.resume()
    }

    func isFollowing(userId: String, completion: @escaping (Bool, Bool?, String?) -> Void) {
        print("DEBUG: isFollowing called for userId: \(userId)")
        
        guard var urlComponents = URLComponents(string: "\(baseURL)/is-following-user/") else {
            print("DEBUG: Invalid URL")
            completion(false, nil, "Invalid URL")
            return
        }
        
        // Add userId as a query parameter
        urlComponents.queryItems = [URLQueryItem(name: "user_id", value: userId)]
        
        guard let url = urlComponents.url else {
            print("DEBUG: Failed to create URL with query parameters")
            completion(false, nil, "Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = AuthenticationService.shared.authToken {
            request.setValue("Token \(token)", forHTTPHeaderField: "Authorization")
            print("DEBUG: Auth token added to request")
        } else {
            print("DEBUG: No auth token available")
        }
        
        print("DEBUG: Sending request to \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(false, nil, "Network error: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                completion(false, nil, "No data received")
                return
            }
            
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {                    
                    if let success = json["success"] as? Bool, success {
                        if let isFollowing = json["is_following"] as? Bool {
                            completion(true, isFollowing, nil)
                        } else {
                            completion(false, nil, "Invalid response format: missing is_following")
                        }
                    } else {
                        let message = json["message"] as? String ?? "Failed to check following status"
                        completion(false, nil, message)
                    }
                } else {
                    completion(false, nil, "Invalid response format")
                }
            } catch {
                completion(false, nil, "Error parsing response: \(error.localizedDescription)")
            }
        }.resume()
    }

    func getUserRecipeBooks(userId: String, completion: @escaping (Bool, [RecipeBook]?, String?) -> Void) {
        guard var urlComponents = URLComponents(string: "\(baseURL)/get-user-recipe-books/") else {
            print("DEBUG: Invalid URL")
            completion(false, nil, "Invalid URL")
            return
        }
        
        urlComponents.queryItems = [URLQueryItem(name: "user_id", value: userId)]
        
        guard let url = urlComponents.url else {
            print("DEBUG: Failed to create URL with query parameters")
            completion(false, nil, "Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = AuthenticationService.shared.authToken {
            request.setValue("Token \(token)", forHTTPHeaderField: "Authorization")
            print("DEBUG: Auth token added to request")
        } else {
            print("DEBUG: No auth token available")
        }
        
        print("DEBUG: Sending request to \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("DEBUG: Network error: \(error.localizedDescription)")
                completion(false, nil, "Network error: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("DEBUG: HTTP Status Code: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("DEBUG: No data received")
                completion(false, nil, "No data received")
                return
            }
            
            print("DEBUG: Received data: \(String(data: data, encoding: .utf8) ?? "Unable to convert data to string")")
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601  // Ensure this matches your date format
                let response = try decoder.decode(GetUserRecipeBooksResponse.self, from: data)
                print("DEBUG: Successfully decoded recipe books")
                completion(true, response.recipeBooks, nil)
            } catch {
                print("DEBUG: Error parsing response: \(error.localizedDescription)")
                completion(false, nil, "Error parsing response: \(error.localizedDescription)")
            }
        }.resume()
    }

    func createRecipeBook(recipeBook: RecipeBook, completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: "\(baseURL)/create-recipe-book/") else {
            completion(false, "Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = AuthenticationService.shared.authToken {
            request.setValue("Token \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601  // Adjust if your date format is different
            let jsonData = try encoder.encode(recipeBook)
            request.httpBody = jsonData
        } catch {
            completion(false, "Error encoding recipe book: \(error.localizedDescription)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(false, "Network error: \(error.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                completion(false, "Server error")
                return
            }
            
            completion(true, nil)
        }.resume()
    }
}

// Define a response model to match the JSON structure
struct GetUserRecipeBooksResponse: Codable {
    let success: Bool
    let userId: String
    let recipeBooks: [RecipeBook]
    
    enum CodingKeys: String, CodingKey {
        case success
        case userId = "user_id"
        case recipeBooks = "recipe_books"
    }
}
