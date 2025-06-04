import SwiftUI

struct ShopView: View {
    @StateObject private var viewModel = ShopViewModel()
    @ObservedObject var recipeManager: RecipeManager
    
    var body: some View {
        NavigationView {
            List {
                GroceryListSection(viewModel: viewModel)
                PantryView()
                RecipesSection(viewModel: viewModel, recipeManager: recipeManager)
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Shop")
            .toolbar {
                EditButton()
            }
            .overlay(LoadingOverlay(isLoading: $viewModel.isLoading))
        }
        .sheet(isPresented: $viewModel.showingAddGroceryItem) {
            AddGroceryItemView(groceryList: $viewModel.groceryList)
        }
        //.sheet(isPresented: $viewModel.showingAddRecipe) {
        //    SearchRecipeView()
        //}
    }
}

struct ShopView_Previews: PreviewProvider {
    static var previews: some View {
        ShopView(recipeManager: RecipeManager())
    }
}
