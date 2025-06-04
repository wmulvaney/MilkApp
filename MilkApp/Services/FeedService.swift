import Foundation

struct FeedResponse: Codable {
    let success: Bool
    let page: Int
    let totalPages: Int
    let recipes: [Recipe]
    
    enum CodingKeys: String, CodingKey {
        case success, page, recipes
        case totalPages = "total_pages"
    }
}

class FeedService: ObservableObject {
    static let shared = FeedService()
    private let baseURL = "http://127.0.0.1:8000"  // or your machine's IP address
    
    @Published var recipes: [Recipe] = []
    @Published var currentPage = 0
    @Published var totalPages = 1
    
    func fetchHomeFeed(page: Int = 1, itemsPerPage: Int = 10, completion: @escaping (Result<[Recipe], Error>) -> Void) {
        print("FeedService: Fetching home feed for page \(page). Current totalPages: \(totalPages)")
        
        guard var urlComponents = URLComponents(string: "\(baseURL)/home-feed/") else {
            print("FeedService: Invalid URL")
            completion(.failure(NSError(domain: "FeedService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        // Add query parameters for pagination
        urlComponents.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "items_per_page", value: "\(itemsPerPage)")
        ]
        
        guard let url = urlComponents.url else {
            print("FeedService: Failed to create URL with components")
            completion(.failure(NSError(domain: "FeedService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        print("FeedService: Request URL: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add authentication token if available
        if let token = AuthenticationService.shared.authToken {
            request.addValue("Token \(token)", forHTTPHeaderField: "Authorization")
            print("FeedService: Added auth token to request")
        } else {
            print("FeedService: No auth token available")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("FeedService: Network error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("FeedService: HTTP Status Code: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("FeedService: No data received")
                completion(.failure(NSError(domain: "FeedService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            print("FeedService: Received data of size: \(data.count) bytes")
            
            do {
                let feedResponse = try JSONDecoder().decode(FeedResponse.self, from: data)
                print("FeedService: Successfully decoded FeedResponse")
                print("FeedService: Received - Page: \(feedResponse.page), Total Pages: \(feedResponse.totalPages), Recipes Count: \(feedResponse.recipes.count)")
                
                DispatchQueue.main.async {
                    self.currentPage = feedResponse.page
                    self.totalPages = feedResponse.totalPages
                    
                    if page == 1 {
                        self.recipes = feedResponse.recipes
                        print("FeedService: Reset recipes array with \(self.recipes.count) items")
                    } else {
                        self.recipes.append(contentsOf: feedResponse.recipes)
                        print("FeedService: Appended \(feedResponse.recipes.count) recipes, total now: \(self.recipes.count)")
                    }
                    completion(.success(feedResponse.recipes))
                }
            } catch {
                print("FeedService: JSON Decoding Error: \(error)")
                if let dataString = String(data: data, encoding: .utf8) {
                    print("FeedService: Raw JSON data: \(dataString)")
                }
                completion(.failure(error))
            }
        }.resume()
        
        print("FeedService: URL task started")
    }
}
