import SwiftUI

struct RecipeBookView: View {
    @StateObject private var authService = AuthenticationService.shared
    @ObservedObject var recipeManager: RecipeManager
    @State private var recipes: [Recipe] = []
    @State private var currentPage = 0
    @State private var pageViewController: UIPageViewController?
    @State private var imageHeight: CGFloat = 0
    @State private var showingUserSettings = false
    @State private var showingUserProfile = false
    
    var user: User?
    
    var mealTypes: [MealType] {
        Array(Set(recipes.map { $0.mealType })).sorted { $0.rawValue < $1.rawValue }
    }
    
    var body: some View {
        NavigationView {
            Group {
                if recipes.isEmpty {
                    Text("No recipes available")
                        .font(.title)
                        .foregroundColor(.secondary)
                } else {
                    GeometryReader { geometry in
                        HStack(spacing: 0) {
                            PageViewController(pages: recipes.map { RecipePageView(recipe: $0, screenWidth: geometry.size.width * 0.9, imageHeight: $imageHeight, recipeManager: recipeManager) }, currentPage: $currentPage)
                                .onAppear { pageViewController = findUIPageViewController() }
                                .frame(width: geometry.size.width * 0.9)
                            
                            ZStack(alignment: .bottom) {
                                Color.clear
                                VStack(spacing: 1) {
                                    ForEach(mealTypes, id: \.self) { mealType in
                                        MealTypeTab(
                                            mealType: mealType,
                                            isSelected: recipes.indices.contains(currentPage) && recipes[currentPage].mealType == mealType,
                                            height: (geometry.size.height - CGFloat(mealTypes.count - 1)) / CGFloat(mealTypes.count),
                                            action: {
                                                jumpToMealType(mealType)
                                            }
                                        )
                                    }
                                }
                                .background(Color.gray.opacity(0.2))
                                .frame(height: geometry.size.height)
                            }
                            .frame(width: geometry.size.width * 0.1)
                            .clipped()
                        }
                    }
                }
            }
            .navigationTitle(user == nil ? "Recipe Book" : "\(user!.username)'s Recipe Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        if user == nil {
                            showingUserSettings = true
                        } else {
                            showingUserProfile = true
                        }
                    }) {
                        ProfileImageView(authService: authService, user: user)
                    }
                }
            }
        }
        .sheet(isPresented: $showingUserSettings) {
            UserSettingsView()
        }
        .sheet(isPresented: $showingUserProfile) {
            if let user = user {
                UserProfileView(user: user)
            }
        }
        .onAppear(perform: fetchRecipes)
        .onReceive(NotificationCenter.default.publisher(for: .refreshRecipes)) { _ in
            fetchRecipes()
        }
    }
    
    private func fetchRecipes() {
        let userId = user?.id ?? authService.currentUser?.id
        guard let userId = userId else {
            print("No user ID available")
            return
        }
        
        let baseURL = "http://127.0.0.1:8000"  // or your machine's IP address
        guard let url = URL(string: "\(baseURL)/get-user-recipes/?user_id=\(userId)") else {
            print("Invalid URL")
            return
        }
        
        guard let token = authService.authToken else {
            print("No authentication token available")
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Token \(token)", forHTTPHeaderField: "Authorization")
        
        print("Fetching recipes from URL: \(url)")
        print("Using token: \(token)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching recipes: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
            }
            
            print("Received data: \(String(data: data, encoding: .utf8) ?? "Unable to convert data to string")")
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                
                let recipeResponse = try decoder.decode(RecipeResponse.self, from: data)
                
                print("Successfully decoded RecipeResponse")
                print("Number of recipes: \(recipeResponse.recipes.count)")
                
                DispatchQueue.main.async {
                    self.recipes = recipeResponse.recipes.sorted(by: { $0.mealType.rawValue < $1.mealType.rawValue })
                    self.currentPage = 0
                    print("Updated recipes array. New count: \(self.recipes.count)")
                }
            } catch let DecodingError.dataCorrupted(context) {
                print("Data corrupted: \(context)")
            } catch let DecodingError.keyNotFound(key, context) {
                print("Key not found: \(key), \(context)")
            } catch let DecodingError.valueNotFound(value, context) {
                print("Value not found: \(value), \(context)")
            } catch let DecodingError.typeMismatch(type, context) {
                print("Type mismatch: \(type), \(context)")
            } catch {
                // If that fails, try to decode as an ErrorResponse
                do {

                    let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
                    print("Server error: \(errorResponse.error)")
                    DispatchQueue.main.async {
                        self.recipes = []
                    }
                } catch {
                    print("Error decoding data: \(error)")
                    if let dataString = String(data: data, encoding: .utf8) {
                        print("Received data: \(dataString)")
                    }
                    DispatchQueue.main.async {
                        self.recipes = []
                    }
                }
            }
        }.resume()
    }
    
    private func jumpToMealType(_ mealType: MealType) {
        if recipes[currentPage].mealType != mealType,
           let index = recipes.firstIndex(where: { $0.mealType == mealType }) {
            currentPage = index
            turnPage(to: index)
        } 
    }
    
    private func turnPage(to index: Int) {
        guard let pageViewController = pageViewController else {
            return
        }
        let direction: UIPageViewController.NavigationDirection = index > currentPage ? .forward : .reverse
        let newViewController = UIHostingController(rootView: RecipePageView(recipe: recipes[index], screenWidth: UIScreen.main.bounds.width * 0.9, imageHeight: $imageHeight, recipeManager: recipeManager))
        pageViewController.setViewControllers([newViewController], direction: direction, animated: true) { completed in
            if completed {
                self.currentPage = index
            }
        }
    }
    
    private func findUIPageViewController() -> UIPageViewController? {
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        let window = windowScene?.windows.first
        
        if let pageViewController = window?.rootViewController?.children.first(where: { $0 is UIPageViewController }) as? UIPageViewController {
            return pageViewController
        }
        
        return nil
    }
}

struct MealTypeTab: View {
    let mealType: MealType
    let isSelected: Bool
    let height: CGFloat
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Rectangle()
                    .fill(isSelected ? Color.blue : Color.clear)
                
                Text(mealType.rawValue)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .rotationEffect(.degrees(-90))
                    .frame(width: height)
            }
        }
        .frame(height: height)
        .background(isSelected ? Color.blue.opacity(0.2) : Color.clear)
    }
}

struct RecipePageView: View {
    let recipe: Recipe
    let screenWidth: CGFloat
    @Binding var imageHeight: CGFloat
    @ObservedObject var recipeManager: RecipeManager
    
    var body: some View {
        RecipeDetailView(recipe: recipe, recipeManager: recipeManager)
            .frame(width: screenWidth)
    }
}

struct RecipeBookView_Previews: PreviewProvider {
    static var previews: some View {
        RecipeBookView(recipeManager: RecipeManager())
    }
}

extension Notification.Name {
    static let refreshRecipes = Notification.Name("refreshRecipes")
}

struct EnlargedProfileImageView: View {
    let user: User
    var body: some View {
        VStack {
            AsyncImage(url: URLHelper.cleanAndValidateURL(user.profileImage ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Text(user.username)
                .font(.title)
                .padding()
        }
    }
}
