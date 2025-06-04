import Foundation

struct AIService {
    static func extractIngredientsFromImage(imageUrl: String, completion: @escaping (Result<[QuantifiedIngredient], Error>) -> Void) {
        let baseURL = "http://127.0.0.1:8000"  // or your machine's IP address
        let url = URL(string: "\(baseURL)/chatgpt-with-image/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["image_url": imageUrl]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "AIService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }

            do {
                if let jsonResult = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let responseString = jsonResult["response"] as? String {
                    let ingredients = responseString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    let extractedIngredients = ingredients.compactMap { ingredient in
                        let parts = ingredient.split(separator: "/", maxSplits: 2, omittingEmptySubsequences: false)
                        if parts.count == 3 {
                            return QuantifiedIngredient(
                                name: String(parts[0]),
                                quantity: Double(String(parts[1])) ?? 1.0,
                                unit: Unit(rawValue: String(parts[2])) ?? .unknown
                            )
                        }
                        return nil
                    }
                    completion(.success(extractedIngredients))
                } else {
                    completion(.failure(NSError(domain: "AIService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
