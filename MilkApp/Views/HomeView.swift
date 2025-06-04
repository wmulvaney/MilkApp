import SwiftUI
// MARK: - Structs
// Recipe

struct RecipeCard: View {
    let recipe: Recipe
    @Binding var isAddedToGroceryList: Bool
    @Binding var showingAddConfirmation: Bool
    @ObservedObject var recipeManager: RecipeManager
    let onTap: () -> Void
    let cardWidth: CGFloat
    
    var body: some View {
        ZStack(alignment: .bottom) {
            recipeImage
                .overlay(
                    LinearGradient(
                        gradient: Gradient(colors: [.clear, .black.opacity(0.7)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            VStack(alignment: .leading, spacing: 5) {
                Text(recipe.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .lineLimit(2)

                Text(recipe.cuisine)
                    .font(.subheadline)

                HStack {
                    Label("\(recipe.calories) cal", systemImage: "flame")
                    Spacer()
                    Label("\(recipe.prepTime + recipe.cookTime) min", systemImage: "clock")
                }
                .font(.caption)

                HStack {
                    Label("\(recipe.servings) servings", systemImage: "person.2")
                    Spacer()
                    AddToGroceryListButton(recipe: recipe, recipeManager: recipeManager)
                }
                .font(.caption)
            }
            .padding(8)
            .foregroundColor(.white)
        }
        .frame(width: cardWidth)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
        .onTapGesture(perform: onTap)
    }
    
    @ViewBuilder
    private var recipeImage: some View {
        AsyncImage(url: URLHelper.cleanAndValidateURL(recipe.image)) { phase in
            switch phase {
            case .empty:
                ProgressView()
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: cardWidth, height: cardWidth * AspectRatioCache.shared.getAspectRatio(for: recipe.id))
                    .clipped()
            case .failure:
                Image(systemName: "photo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: cardWidth, height: cardWidth * AspectRatioCache.shared.getAspectRatio(for: recipe.id))
            @unknown default:
                EmptyView()
            }
        }
    }
}


struct HomeView: View {
    @ObservedObject var recipeManager: RecipeManager
    @ObservedObject var feedService = FeedService.shared
    @State private var showingAddConfirmation = false
    @State private var lastAddedRecipeIndex: Int?
    @State private var selectedRecipe: Recipe?
    @State private var showingRecipeDetail = false
    @State private var addedToGroceryList: [Bool] = []
    
    @State private var isLoading = false
    
    init(recipeManager: RecipeManager) {
        self._recipeManager = ObservedObject(wrappedValue: recipeManager)
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                VStack {
                    // Spacer to push the content below the search bar
                    Spacer().frame(height: 60) // Adjust this value to match your search bar height
                    
                    GeometryReader { geometry in
                        let cardWidth = geometry.size.width / 2 - 15
                        
                        ScrollView {
                            HStack(alignment: .top, spacing: 15) {
                                LazyVStack(spacing: 15) {
                                    ForEach(Array(feedService.recipes.enumerated()), id: \.element.id) { index, recipe in
                                        if index % 2 == 0 {
                                            recipeCardView(for: index, recipe: recipe, width: cardWidth)
                                                .onAppear {
                                                    if index == feedService.recipes.count - 2 {
                                                        loadMoreContent()
                                                    }
                                                }
                                        }
                                    }
                                }
                                
                                LazyVStack(spacing: 15) {
                                    ForEach(Array(feedService.recipes.enumerated()), id: \.element.id) { index, recipe in
                                        if index % 2 != 0 {
                                            recipeCardView(for: index, recipe: recipe, width: cardWidth)
                                                .onAppear {
                                                    if index == feedService.recipes.count - 1 {
                                                        loadMoreContent()
                                                    }
                                                }
                                        }
                                    }
                                }
                            }
                            .padding()
                            
                            if isLoading {
                                ProgressView()
                                    .padding()
                            }
                        }
                    }
                }
                
                SearchRecipeView(recipeManager: recipeManager, showUsers: true)
            }
            .sheet(item: $selectedRecipe) { recipe in
                RecipeDetailView(recipe: recipe, recipeManager: recipeManager)
            }
            .overlay(
                Group {
                    if showingAddConfirmation {
                        Text("Recipe added to your grocery list")
                            .padding()
                            .background(Color.green.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .animation(.easeInOut)
                    }
                }
            )
            .onAppear {
                if feedService.recipes.isEmpty {
                    loadMoreContent()
                }
            }
        }
    }

    @ViewBuilder
    private func recipeCardView(for index: Int, recipe: Recipe, width: CGFloat) -> some View {
        RecipeCard(
            recipe: recipe,
            isAddedToGroceryList: Binding(
                get: { index < addedToGroceryList.count ? addedToGroceryList[index] : false },
                set: { newValue in
                    if index >= addedToGroceryList.count {
                        addedToGroceryList.append(newValue)
                    } else {
                        addedToGroceryList[index] = newValue
                    }
                }
            ),
            showingAddConfirmation: $showingAddConfirmation,
            recipeManager: recipeManager,
            onTap: {
                selectedRecipe = recipe
                showingRecipeDetail = true
            },
            cardWidth: width
        )
    }
    
    private func loadMoreContent() {
        guard !isLoading && feedService.currentPage < feedService.totalPages else {
            print("HomeView: Not loading more content. isLoading: \(isLoading), currentPage: \(feedService.currentPage), totalPages: \(feedService.totalPages)")
            return
        }
        
        print("HomeView: Loading more content for page \(feedService.currentPage + 1)")
        isLoading = true
        feedService.fetchHomeFeed(page: feedService.currentPage + 1) { result in
            isLoading = false
            switch result {
            case .success(let newRecipes):
                print("HomeView: Successfully loaded \(newRecipes.count) new recipes")
                self.addedToGroceryList.append(contentsOf: Array(repeating: false, count: newRecipes.count))
            case .failure(let error):
                print("HomeView: Error loading more recipes: \(error)")
            }
        }
    }
}



struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(recipeManager: RecipeManager())
    }
}
