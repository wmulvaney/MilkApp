import SwiftUI

class ShopViewModel: ObservableObject {
    @Published var groceryList: [QuantifiedIngredient] = []
    @Published var recipes: [Recipe] = sampleRecipes
    @Published var showingAddGroceryItem = false
    @Published var showingAddPantryItem = false
    @Published var showingAddRecipe = false
    @Published var image: UIImage?
    @Published var showingImagePicker = false
    @Published var showExtractIngredientsButton = false
    @Published var imageUrl: String?
    @Published var showingNoImageAlert = false
    @Published var extractedIngredients: [QuantifiedIngredient] = []
    @Published var showingIngredientSelection = false
    @Published var selectedIngredients: Set<UUID> = []
    @Published var showingNoIngredientsAlert = false
    @Published var isLoading = false
    
    func deleteGroceryItem(at offsets: IndexSet) {
        groceryList.remove(atOffsets: offsets)
    }
    
    
    func deleteRecipe(at offsets: IndexSet, recipeManager: RecipeManager) {
        for index in offsets {
            let storedRecipe = recipeManager.storedRecipes[index]
            recipeManager.decrementRecipe(storedRecipe)
        }
    }
    
    func extractIngredientsFromImage() {
        guard let imageUrl = imageUrl else {
            print("No image URL available")
            isLoading = false
            return
        }

        isLoading = true
        AIService.extractIngredientsFromImage(imageUrl: imageUrl) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let ingredients):
                    if !ingredients.isEmpty {
                        self?.extractedIngredients = ingredients
                        self?.selectedIngredients = Set(ingredients.map { $0.id })
                        self?.showingIngredientSelection = true
                    } else {
                        self?.showingNoIngredientsAlert = true
                    }
                case .failure(let error):
                    print("Error: \(error.localizedDescription)")
                    self?.showingNoIngredientsAlert = true
                }
            }
        }
    }
}
