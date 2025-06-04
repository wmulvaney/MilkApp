import SwiftUI

struct GroceryListSection: View {
    @ObservedObject var viewModel: ShopViewModel
    
    var body: some View {
        Section(header: Text("Grocery List")) {
            ForEach(viewModel.groceryList) { item in
                Text(item.name)
            }
            .onDelete(perform: viewModel.deleteGroceryItem)
            
            Button("Add Grocery Item") {
                viewModel.showingAddGroceryItem = true
            }
        }
        .listRowBackground(Color(.systemGray6))
    }
}

struct Ingredient: Identifiable {
    let id = UUID()
    let name: String
    var isInShoppingList: Bool
}

struct RecipesSection: View {
    @ObservedObject var viewModel: ShopViewModel
    @ObservedObject var recipeManager: RecipeManager
    
    var body: some View {
        Section(header: Text("Recipes")) {
            ForEach(recipeManager.storedRecipes) { storedRecipe in
                HStack {
                    Text(storedRecipe.recipe.name)
                    Spacer()
                    Text("x\(storedRecipe.quantity)")
                    AddToGroceryListButton(recipe: storedRecipe.recipe, recipeManager: recipeManager)
                }
            }
            .onDelete { offsets in
                viewModel.deleteRecipe(at: offsets, recipeManager: recipeManager)
            }
            
            Button("Add Recipe") {
                viewModel.showingAddRecipe = true
            }
        }
        .listRowBackground(Color(.systemGray6))
    }
}
