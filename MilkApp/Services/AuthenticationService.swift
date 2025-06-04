import Foundation
import FirebaseStorage
import UIKit
import Combine

class AuthenticationService: ObservableObject {
    static let shared = AuthenticationService()
    let baseURL = "http://127.0.0.1:8000"  // or your machine's IP address
    
    static let authStateDidChangeNotification = "authStateDidChangeNotification"
    
    @Published private(set) var currentUser: User?
    @Published private(set) var isLoggedIn: Bool = false
    @Published var authToken: String?
    
    private let userDefaults = UserDefaults.standard
    private let tokenKey = "authToken"
    
    private init() {
        // Load saved auth token if available
        self.authToken = userDefaults.string(forKey: tokenKey)
        print("Loaded auth token on init: \(self.authToken ?? "No token found")")
        checkStoredSession()
    }
    
    func setLoggedIn(user: User, token: String?) {
        self.currentUser = user
        self.isLoggedIn = true
        
        if let token = token {
            self.authToken = token
            userDefaults.set(token, forKey: tokenKey)
        } else {
            print("No auth token provided during login")
        }
        
        // Save other user data as needed
        userDefaults.set(user.id, forKey: "userId")
        userDefaults.set(user.email, forKey: "userEmail")
        userDefaults.set(user.username, forKey: "userUsername")
        userDefaults.set(user.profileImage, forKey: "userProfileImage")
        
        NotificationCenter.default.post(name: Notification.Name(AuthenticationService.authStateDidChangeNotification), object: nil)
    }
    
    func logout() {
        currentUser = nil
        isLoggedIn = false
        authToken = nil
        
        userDefaults.removeObject(forKey: tokenKey)
        userDefaults.removeObject(forKey: "userId")
        userDefaults.removeObject(forKey: "userEmail")
        userDefaults.removeObject(forKey: "userUsername")
        userDefaults.removeObject(forKey: "userProfileImage")
        NotificationCenter.default.post(name: Notification.Name(AuthenticationService.authStateDidChangeNotification), object: nil)
    }
    
    private func checkStoredSession() {
        if let userId = userDefaults.string(forKey: "userId"),
           let email = userDefaults.string(forKey: "userEmail"),
           let username = userDefaults.string(forKey: "userUsername"),
           let profileImage = userDefaults.string(forKey: "userProfileImage") {
            let user = User(id: userId, name: username, username: username, email: email, profileImage: profileImage)
            currentUser = user
            isLoggedIn = true
        }
    }
    
    func login(email: String, password: String, completion: @escaping (Bool, LoginResponse?) -> Void) {
        let url = URL(string: "\(baseURL)/login/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = ["email": email.lowercased(), "password": password]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        print("Request URL: \(url)")
        print("Request Body: \(String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "")")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("Network Error: \(error.localizedDescription)")
                completion(false, nil)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Response Status Code: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("No data received")
                completion(false, nil)
                return
            }
            
            print("Response Data: \(String(data: data, encoding: .utf8) ?? "")")
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    print("Parsed JSON: \(json)")
                    if let success = json["success"] as? Bool, success,
                       let userData = json["user"] as? [String: Any] {
                        // Login successful
                        let message = json["message"] as? String ?? "Login successful"
                        let userId = userData["id"] as? String
                        let name = userData["name"] as? String
                        let username = userData["username"] as? String
                        let email = userData["email"] as? String
                        let profileImage = userData["profile_image"] as? String
                        
                        // Extract token from the response
                        let token = json["token"] as? String
                        print("Received token from server: \(token ?? "No token received")")
                        
                        if let userId = userId, let username = username, let email = email {
                            let user = User(id: userId, name: name, username: username, email: email, profileImage: profileImage)
                            
                            // Pass the token to setLoggedIn
                            self?.setLoggedIn(user: user, token: token)
                            
                            completion(true, LoginResponse(user: user, token: token, message: message))
                        } else {
                            completion(false, nil)
                        }
                    } else {
                        // Login failed
                        let message = json["message"] as? String ?? "Login failed"
                        completion(false, LoginResponse(user: nil, token: nil, message: message))
                    }
                } else {
                    completion(false, nil)
                }
            } catch {
                print("JSON Parsing Error: \(error.localizedDescription)")
                completion(false, nil)
            }
        }.resume()
    }
    
    func signup(email: String, username: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        let url = URL(string: "\(baseURL)/register/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = ["email": email, "username": username, "password": password]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                completion(false, error.localizedDescription)
                return
            }
            
            guard let data = data else {
                completion(false, "No data received")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let success = json["success"] as? Bool, success,
                       let userData = json["user"] as? [String: Any] {
                        let message = json["message"] as? String ?? "Signup successful"
                        let userId = userData["id"] as? String
                        let name = userData["name"] as? String
                        let username = userData["username"] as? String
                        let email = userData["email"] as? String
                        let profileImage = userData["profile_image"] as? String
                        let token = json["token"] as? String  // Extract token from response
                        
                        if let userId = userId, let username = username, let email = email {
                            let user = User(id: userId, name: name ?? username, username: username, email: email, profileImage: profileImage)
                            self?.setLoggedIn(user: user, token: token)  // Pass token to setLoggedIn
                            
                            completion(true, message)
                        } else {
                            completion(false, "Invalid user data")
                        }
                    } else {
                        let message = json["message"] as? String ?? "Signup failed"
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
    
    func addRecipe(recipe: Recipe, completion: @escaping (Bool, String?, String?) -> Void) {
        let url = URL(string: "\(baseURL)/add-recipe/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let recipeData: [String: Any] = [
            "name": recipe.name,
            "created_by": currentUser?.id ?? "",
            "prepTime": recipe.prepTime,
            "cookTime": recipe.cookTime,
            "calories": recipe.calories,
            "cuisine": recipe.cuisine,
            "servings": recipe.servings,
            "description": recipe.description ?? "",
            "ingredients": recipe.ingredients,
            "instructions": recipe.instructions,
            "image": recipe.image,
            "mealType": recipe.mealType.rawValue
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: recipeData)
        } catch {
            completion(false, "Error encoding recipe data", nil)
            return
        }

        print("Request URL: \(url)")
        print("Request Body: \(String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "")")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                completion(false, "Network error: \(error.localizedDescription)", nil)
                return
            }
            
            guard let data = data else {
                print("No data received from server")
                completion(false, "No data received from server", nil)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status code: \(httpResponse.statusCode)")
            }
            
            do {
                if let jsonResult = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    print("Server response: \(jsonResult)")
                    if let message = jsonResult["message"] as? String, message == "Recipe added successfully" {
                        let recipeId = jsonResult["id"].flatMap { String(describing: $0) }
                        if let recipeId = recipeId {
                            // Post notification to refresh recipes
                            DispatchQueue.main.async {
                                NotificationCenter.default.post(name: .refreshRecipes, object: nil)
                            }
                        }
                        completion(true, "Recipe added successfully", recipeId)
                    } else {
                        let errorMessage = jsonResult["message"] as? String ?? "Unknown error occurred"
                        completion(false, errorMessage, nil)
                    }
                } else {
                    completion(false, "Invalid response format", nil)
                }
            } catch {
                print("JSON parsing error: \(error.localizedDescription)")
                completion(false, "JSON parsing error: \(error.localizedDescription)", nil)
            }
        }.resume()
    }
    
    func updateProfileImage(url: String) {
        // Update the current user's profile image URL
        if var updatedUser = currentUser {
            updatedUser.profileImage = url
            currentUser = updatedUser
        }
        
        // Save the updated user information to UserDefaults
        if let encodedUser = try? JSONEncoder().encode(currentUser) {
            userDefaults.set(encodedUser, forKey: "currentUser")
        }
        
        // Notify observers of the change
        objectWillChange.send()
        
        // If you have a separate notification for profile updates, you can post it here
        NotificationCenter.default.post(name: .userProfileDidUpdate, object: nil)
        
        // If you need to update the server with this new URL, you can call an API here
        // updateProfileImageOnServer(url: url)
    }
}

// Extension to add a custom notification name
extension Notification.Name {
    static let userProfileDidUpdate = Notification.Name("userProfileDidUpdate")
}

class StorageService {
    static let shared = StorageService()
    private init() {}
    
    func uploadImage(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])))
            return
        }
        
        let storageRef = Storage.storage().reference()
        let imageRef = storageRef.child("recipe_images/\(UUID().uuidString).jpg")
        
        imageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            imageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                } else if let url = url {
                    completion(.success(url.absoluteString))
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"])))
                }
            }
        }
    }
}

struct LoginResponse {
    let user: User?
    let token: String?
    let message: String
}

struct AuthResponse {
    let success: Bool
    let userId: String?
    let message: String
}

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
