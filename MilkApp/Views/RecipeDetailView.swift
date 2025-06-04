import SwiftUI

struct RecipeDetailView: View {
    let recipe: Recipe
    @ObservedObject var recipeManager: RecipeManager
    @State private var showingAddConfirmation = false
    @EnvironmentObject var authService: AuthenticationService
    @State private var showingEditView = false
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    recipeImage
                        .frame(width: geometry.size.width, height: min(300, geometry.size.height * 0.4))
                        .clipped()
                    
                    HStack {
                        AddToGroceryListButton(recipe: recipe, recipeManager: recipeManager)
                        .padding(4)
                        
                        if let storedRecipe = getStoredRecipe() {
                            Text("Quantity: \(storedRecipe.quantity)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if isCurrentUserCreator {
                            Button(action: {
                                showingEditView = true
                            }) {
                                Text("Edit")
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(5)
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text(recipe.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(recipe.cuisine)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Label("\(recipe.prepTime + recipe.cookTime) min", systemImage: "clock")
                            Spacer()
                            Label("\(recipe.calories) cal", systemImage: "flame")
                            Spacer()
                            Label("\(recipe.servings) servings", systemImage: "person.2")
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        
                        Text("Ingredients")
                            .font(.headline)
                            .padding(.top)
                        
                        ForEach(recipe.ingredients, id: \.name) { ingredient in
                            HStack {
                                Text("•")
                                Text(ingredient.name)
                                Spacer()
                                Text("\(ingredient.quantity, specifier: "%.1f") \(ingredient.unit.rawValue)")
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Text("Instructions")
                            .font(.headline)
                            .padding(.top)
                        
                        ForEach(recipe.instructions.indices, id: \.self) { index in
                            Text("\(index + 1). \(recipe.instructions[index])")
                                .padding(.bottom, 5)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer() // Add this to push content to the top
                }
                .frame(width: geometry.size.width)
            }
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
        .sheet(isPresented: $showingEditView) {
            EditRecipeView(recipe: recipe, recipeManager: recipeManager)
        }
        .navigationBarHidden(false)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var isRecipeInList: Bool {
        recipeManager.storedRecipes.contains { $0.recipe.id == recipe.id }
    }
    
    private func getStoredRecipe() -> StoredRecipe? {
        recipeManager.storedRecipes.first { $0.recipe.id == recipe.id }
    }
    
    private func addToGroceryList() {
        recipeManager.addOrIncrementRecipe(recipe)
        
        withAnimation {
            showingAddConfirmation = true
        }
        
        // Hide the confirmation message after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showingAddConfirmation = false
            }
        }
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
            case .failure:
                Image(systemName: "photo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            @unknown default:
                EmptyView()
            }
        }
    }
    
    private var isCurrentUserCreator: Bool {
        AuthenticationService.shared.currentUser?.id == recipe.createdBy?.id
    }
}
