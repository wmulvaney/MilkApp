import SwiftUI

struct SearchRecipeView: View {
    @ObservedObject var recipeManager: RecipeManager
    @State var showUsers = false
    @State private var searchText = ""
    @State private var debouncedSearchText = ""
    @State private var searchResults: SearchResponse?
    @State private var isSearchActive = false
    @State private var selectedRecipe: Recipe?
    @State private var selectedUser: User?
    @State private var isLoading = false
    @State private var searchTask: Task<Void, Never>?
    
    var body: some View {
        ZStack(alignment: .top) {
            searchBar
                .onTapGesture {
                    isSearchActive = true
                }
            
            if isSearchActive {
                searchOverlay
                searchPopup
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isSearchActive)
        .sheet(item: $selectedRecipe) { recipe in
            RecipeDetailView(recipe: recipe, recipeManager: recipeManager)
        }
        .sheet(item: $selectedUser) { user in
            RecipeBookView(recipeManager: recipeManager, user: user)
        }
    }
    
    private var searchOverlay: some View {
        Color.black.opacity(0.3)
            .edgesIgnoringSafeArea(.all)
            .onTapGesture {
                isSearchActive = false
                searchText = ""
                searchResults = nil
            }
    }
    
    private var searchPopup: some View {
        VStack(spacing: 0) {
            searchBar
            searchResultsView
        }
        .background(Color(.systemBackground))
        .cornerRadius(30)
        .shadow(radius: 10)
        .transition(.opacity)
        .zIndex(1)
    }
    
    private var searchResultsView: some View {
        Group {
            if isLoading {
                ProgressView()
                    .padding()
            } else if let results = searchResults, !results.recipes.isEmpty || !results.users.isEmpty {
                searchResultsList(results: results)
            } else if !debouncedSearchText.isEmpty && searchResults != nil {
                Text("No results found")
                    .foregroundColor(.gray)
                    .padding()
            }
        }
    }
    
    private func searchResultsList(results: SearchResponse) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if !results.recipes.isEmpty {
                    recipeSection(recipes: results.recipes)
                }
                
                if showUsers && !results.users.isEmpty {
                    userSection(users: results.users)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: min(CGFloat((results.recipes.count + (results.users.isEmpty ? 0 : results.users.count)) * 91 + (showUsers && !results.users.isEmpty ? 100 : 0) + 24), 400))
    }
    
    private func recipeSection(recipes: [Recipe]) -> some View {
        Section(header: sectionHeader("Recipes")) {
            ForEach(recipes) { recipe in
                RecipeRow(recipe: recipe)
                    .padding(.vertical, 8)
                    .onTapGesture {
                        selectedRecipe = recipe
                        isSearchActive = false
                    }
            }
        }
    }
    
    private func userSection(users: [User]) -> some View {
        Section(header: sectionHeader("Users")) {
            ForEach(users) { user in
                UserRow(user: user)
                    .padding(.vertical, 8)
                    .onTapGesture {
                        selectedUser = user
                        isSearchActive = false
                    }
            }
        }
    }
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.primary)
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 8)
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            if isSearchActive {
                TextField("Search recipes...", text: $searchText)
                    .onChange(of: searchText) { newValue in
                        debounceSearch()
                    }
            } else {
                Text(searchText.isEmpty ? "Search recipes..." : searchText)
                    .foregroundColor(searchText.isEmpty ? .gray : .primary)
            }
            Spacer()
            if isSearchActive && !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    debouncedSearchText = ""
                    searchResults = nil
                    searchTask?.cancel()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(30)
    }

    private func searchRecipes(query: String) {
        guard !query.isEmpty else {
            searchResults = nil
            return
        }
        
        isLoading = true
        
        let baseURL = "http://127.0.0.1:8000"  // or your machine's IP address
        let urlString = "\(baseURL)/search/?query=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        print("URL: \(urlString)")
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    print("No data received")
                    return
                }
                
                // Print raw JSON data
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Raw JSON response: \(jsonString)")
                }
                
                do {
                    // First, try to decode as ErrorResponse
                    if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                        print("API Error: \(errorResponse.error)")
                        searchResults = nil
                        return
                    }
                    
                    // If it's not an error, try to decode as SearchResponse
                    let decodedResponse = try JSONDecoder().decode(SearchResponse.self, from: data)
                    if decodedResponse.success {
                        searchResults = decodedResponse
                    } else {
                        print("API request was not successful")
                        searchResults = nil
                    }
                } catch {
                    print("Decoding error: \(error)")
                    searchResults = nil
                }
            }
        }.resume()
    }
    private func debounceSearch() {
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            if !Task.isCancelled {
                await MainActor.run {
                    debouncedSearchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if debouncedSearchText.count >= 1 {
                        searchRecipes(query: debouncedSearchText)
                    } else {
                        searchResults = nil
                        isLoading = false
                    }
                }
            }
        }
    }
}

struct SearchResponse: Codable {
    let success: Bool
    let recipes: [Recipe]
    let users: [User]
}

struct RecipeRow: View {
    let recipe: Recipe
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AsyncImage(url: URL(string: recipe.image)) { image in
                image.resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray
            }
            .frame(width: 75, height: 75)
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.name)
                    .font(.headline)
                    .lineLimit(2)
                Text("\(recipe.prepTime + recipe.cookTime) mins | \(recipe.calories) cal")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(.horizontal)
    }
}

struct UserRow: View {
    let user: User
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: user.profileImage ?? "")) { image in
                image.resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.gray)
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
            Text(user.username)
                .font(.headline)
            
            Spacer()
        }
        .padding(.horizontal)
    }
}

struct ErrorResponse: Codable {
    let error: String
}
