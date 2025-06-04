import SwiftUI
import Combine

class PantryDataManager: ObservableObject {
    @Published var pantryItems: [QuantifiedIngredient] = []
    private var cancellables: Set<AnyCancellable> = []
    private let baseURL = "http://127.0.0.1:8000"  // Update this to match your server URL

    static let shared = PantryDataManager()
    init() {
        loadPantryItems()
    }

    func loadPantryItems() {
        guard let url = URL(string: "\(baseURL)/get-user-pantry/") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Token \(AuthenticationService.shared.authToken ?? "")", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            // .handleEvents(receiveOutput: { data in
            //     // if let jsonString = String(data: data, encoding: .utf8) {
            //     //     print("Received JSON: \(jsonString)")  // Print the raw JSON response
            //     // }
            // })
            .decode(type: PantryResponse.self, decoder: JSONDecoder())  // Decode into PantryResponse
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(let error) = completion {
                    print("Error loading pantry items: \(error)")
                }
            } receiveValue: { [weak self] response in
                self?.pantryItems = response.pantry  // Access the pantry array
            }
            .store(in: &cancellables)
        print("Pantry items loaded: \(self.pantryItems.count ?? 0)")
    }

    func addIngredientsToPantry(_ ingredients: [QuantifiedIngredient]) {
        self.pantryItems.append(contentsOf: ingredients)
        guard let url = URL(string: "\(baseURL)/add-ingredients-to-pantry/") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Token \(AuthenticationService.shared.authToken ?? "")", forHTTPHeaderField: "Authorization")

        do {
            request.httpBody = try JSONEncoder().encode(ingredients)
        } catch {
            print("Error encoding ingredients: \(error)")
            return
        }

        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .handleEvents(receiveOutput: { data in
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Response JSON: \(jsonString)")
                }
            })
            .decode(type: AddIngredientsResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(let error) = completion {
                    print("Error adding ingredients to pantry: \(error)")
                }
            } receiveValue: { [weak self] response in
                if let pantryItems = response.pantryItems {
                    self?.pantryItems = pantryItems
                }
            }
            .store(in: &cancellables)
    }

    func removeIngredientFromPantry(_ ingredientId: UUID) {
        guard let url = URL(string: "\(baseURL)/remove-ingredient-from-pantry/") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Token \(AuthenticationService.shared.authToken ?? "")", forHTTPHeaderField: "Authorization")

        let body = ["ingredientId": ingredientId.uuidString]
        request.httpBody = try? JSONEncoder().encode(body)

        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: [QuantifiedIngredient].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(let error) = completion {
                    print("Error removing ingredient from pantry: \(error)")
                }
            } receiveValue: { [weak self] updatedItems in
                self?.pantryItems = updatedItems
            }
            .store(in: &cancellables)
    }

    func clearPantry() {
        guard let url = URL(string: "\(baseURL)/clear-pantry/") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Token \(AuthenticationService.shared.authToken ?? "")", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: [QuantifiedIngredient].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(let error) = completion {
                    print("Error clearing pantry: \(error)")
                }
            } receiveValue: { [weak self] updatedItems in
                self?.pantryItems = updatedItems
            }
            .store(in: &cancellables)
    }

    func editPantryItem(_ item: QuantifiedIngredient) {
        guard let url = URL(string: "\(baseURL)/edit_pantry_item/") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Token \(AuthenticationService.shared.authToken ?? "")", forHTTPHeaderField: "Authorization")

        do {
            request.httpBody = try JSONEncoder().encode(item)
        } catch {
            print("Error encoding ingredient: \(error)")
            return
        }

        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: [QuantifiedIngredient].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(let error) = completion {
                    print("Error editing pantry item: \(error)")
                }
            } receiveValue: { [weak self] updatedItems in
                self?.pantryItems = updatedItems
            }
            .store(in: &cancellables)
    }
}

struct AddIngredientsResponse: Codable {
    let success: Bool
    let message: String
    let pantryItems: [QuantifiedIngredient]?
}

// Define a new struct to match the server's response structure
struct PantryResponse: Codable {
    let success: Bool
    let pantry: [QuantifiedIngredient]
}
