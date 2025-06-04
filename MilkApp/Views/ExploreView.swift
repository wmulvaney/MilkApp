import SwiftUI
// MARK: - Structs
// Recipe

struct ExploreView: View {
    let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 150), spacing: 1)
    ]
    
    @ObservedObject var recipeManager: RecipeManager
    @State private var selectedRecipe: Recipe?
    @State private var showingRecipeDetail = false
    
    @State private var recipes: [Recipe] = sampleRecipes
    @State private var isSearchActive = false
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                VStack {
                    // Spacer to push the grid view below the search bar
                    Spacer().frame(height: 60) // Adjust this value to match your search bar height
                    
                    // Grid view
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 1) {
                            ForEach(recipes) { recipe in
                                RecipeGridItem(recipe: recipe)
                                    .aspectRatio(1, contentMode: .fit)
                                    .padding(.horizontal, 8)
                                    .onTapGesture {
                                        selectedRecipe = recipe
                                        showingRecipeDetail = true
                                    }
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                }
                
                SearchRecipeView(recipeManager: recipeManager, showUsers: true)
            }
            .sheet(item: $selectedRecipe) { recipe in
                RecipeDetailView(recipe: recipe, recipeManager: recipeManager)
            }
        }
    }
}

struct RecipeGridItem: View {
    let recipe: Recipe
    
    var body: some View {
        Group {
            AsyncImage(url: URLHelper.cleanAndValidateURL(recipe.image)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    Image(systemName: "photo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: UIScreen.main.bounds.width / 3, height: UIScreen.main.bounds.width / 3)
            .clipped()
        }
    }
}

struct ExploreView_Previews: PreviewProvider {
    static var previews: some View {
        ExploreView(recipeManager: RecipeManager())
    }
}
