import SwiftUI

struct AddToGroceryListButton: View {
    let recipe: Recipe
    @ObservedObject var recipeManager: RecipeManager
    @State private var isAddedToGroceryList = false
    @State private var showingAddConfirmation = false
    
    var body: some View {
        Button(action: addToGroceryList) {
            Image(systemName: isAddedToGroceryList ? "checkmark.circle.fill" : "plus.circle.fill")
                .foregroundColor(isAddedToGroceryList ? .green : .blue)
                .font(.title)
                .padding(8)
                .background(Color.white.opacity(0.8))
                .clipShape(Circle())
        }
        .overlay(
            Group {
                if showingAddConfirmation {
                    Text("Added to grocery list")
                        .padding(6)
                        .background(Color.green.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .font(.caption)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .animation(.easeInOut)
                        .offset(y: 30)
                }
            }
        )
    }
    
    private func addToGroceryList() {
        recipeManager.addOrIncrementRecipe(recipe)
        
        withAnimation {
            isAddedToGroceryList = true
            showingAddConfirmation = true
        }
        
        // Revert button state and hide confirmation after 1 second
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            withAnimation {
                isAddedToGroceryList = false
                showingAddConfirmation = false
            }
        }
    }
}

struct AddToGroceryListButton_Previews: PreviewProvider {
    static var previews: some View {
        AddToGroceryListButton(
            recipe: Recipe(
                id: "1",
                name: "Test Recipe",
                image: "",
                ingredients: [],
                instructions: [],
                prepTime: 10,
                cookTime: 20,
                calories: 300,
                cuisine: "Italian",
                servings: 4,
                description: "",
                mealType: .dinner,
                createdBy: User(
                    id: "1",
                    name: "william wallace",
                    username: "william_wallace",
                    email: "john.doe@example.com",
                    profileImage: "https://imgs.search.brave.com/Aqyck6KGW7GjY4a_4nogz0H2B1kTCQi2QbnBzwYNyJs/rs:fit:500:0:0:0/g:ce/aHR0cHM6Ly90My5m/dGNkbi5uZXQvanBn/LzA4LzE1LzM4LzUw/LzM2MF9GXzgxNTM4/NTA4N18xeUFac3JC/aDFMTk1FaXVQMVdQ/NWlaS2pQdTdFbjFH/by5qcGc"
                )
            ),
            recipeManager: RecipeManager()
        )
    }
}
