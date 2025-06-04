import Foundation

class RecipeManager: ObservableObject {
    @Published var storedRecipes: [StoredRecipe] = []
    private let storedRecipesKey = "storedRecipes"
    
    // Add this line to define the baseURL
    private let baseURL = "http://127.0.0.1:8000"  // Replace with your actual API base URL
    
    init() {
        loadRecipes()
    }
    
    func loadRecipes() {
        if let data = UserDefaults.standard.data(forKey: storedRecipesKey) {
            if let decodedRecipes = try? JSONDecoder().decode([StoredRecipe].self, from: data) {
                storedRecipes = decodedRecipes
            }
        }
    }
    
    func saveRecipes() {
        if let encodedData = try? JSONEncoder().encode(storedRecipes) {
            UserDefaults.standard.set(encodedData, forKey: storedRecipesKey)
        }
    }
    
    func addOrIncrementRecipe(_ recipe: Recipe) {
        if let index = storedRecipes.firstIndex(where: { $0.recipe.id == recipe.id }) {
            storedRecipes[index].quantity += 1
        } else {
            let newStoredRecipe = StoredRecipe(recipe: recipe)
            storedRecipes.append(newStoredRecipe)
        }
        saveRecipes()
    }
    
    func decrementRecipe(_ storedRecipe: StoredRecipe) {
        if let index = storedRecipes.firstIndex(where: { $0.id == storedRecipe.id }) {
            if storedRecipes[index].quantity > 1 {
                storedRecipes[index].quantity -= 1
            } else {
                storedRecipes.remove(at: index)
            }
            saveRecipes()
        }
    }
    func updateRecipe(_ recipe: Recipe, completion: @escaping (Result<Recipe, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/edit-recipe/\(recipe.id)/") else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        guard let token = AuthenticationService.shared.authToken else {
            completion(.failure(NetworkError.unauthorized))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Token \(token)", forHTTPHeaderField: "Authorization")

        do {
            let jsonData = try JSONEncoder().encode(recipe)
            request.httpBody = jsonData
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
                if httpResponse.statusCode == 400 {
                    print("Bad Request - Server Response:")
                    if let data = data, let responseString = String(data: data, encoding: .utf8) {
                        print(responseString)
                    }
                }
            }

            guard let data = data else {
                print("No data received from server")
                DispatchQueue.main.async {
                    completion(.failure(NetworkError.noData))
                }
                return
            }

            do {
                let serverResponse = try JSONDecoder().decode(ServerResponse.self, from: data)
                let updatedRecipe = serverResponse.recipe
                print("Updated recipe: \(updatedRecipe)")
                DispatchQueue.main.async {
                    self.updateLocalRecipe(updatedRecipe)
                    completion(.success(updatedRecipe))
                }
            } catch {
                print("JSON Decoding error: \(error.localizedDescription)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Raw server response: \(responseString)")
                }
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
    }

    private func updateLocalRecipe(_ updatedRecipe: Recipe) {
        if let index = storedRecipes.firstIndex(where: { $0.recipe.id == updatedRecipe.id }) {
            storedRecipes[index].recipe = updatedRecipe
            saveRecipes()
        }
    }
}

// Add this enum if it's not already defined elsewhere in your project
enum NetworkError: Error {
    case invalidURL
    case noData
    case unauthorized
    // Add other network-related error cases as needed
}

struct ServerResponse: Codable {
    let success: Bool
    let message: String
    let recipe: Recipe
}
