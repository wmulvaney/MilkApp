import SwiftUI

struct EditRecipeView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var recipeManager: RecipeManager
    @State private var editedRecipe: EditableRecipe
    @State private var image: UIImage?
    @State private var imageUrl: String?
    @State private var showingAlert = false
    @State private var alertMessage = ""

    init(recipe: Recipe, recipeManager: RecipeManager) {
        self._editedRecipe = State(initialValue: EditableRecipe(from: recipe))
        self._imageUrl = State(initialValue: recipe.image)
        self._image = State(initialValue: nil)  // Explicitly set to nil
        self.recipeManager = recipeManager
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Basic Information")) {
                    TextField("Recipe Name", text: $editedRecipe.name)
                    TextField("Cuisine", text: $editedRecipe.cuisine)
                    Picker("Meal Type", selection: $editedRecipe.mealType) {
                        ForEach(MealType.allCases, id: \.self) { mealType in
                            Text(mealType.rawValue).tag(mealType)
                        }
                    }
                }

                Section(header: Text("Image")) {
                    ImageUploadButton(image: $image, imageUrl: $imageUrl)
                        .listRowInsets(EdgeInsets())
                        .frame(maxWidth: .infinity)
                }

                Section(header: Text("Ingredients")) {
                    ForEach(editedRecipe.ingredients.indices, id: \.self) { index in
                        HStack {
                            TextField("Ingredient", text: $editedRecipe.ingredients[index].name)
                            TextField("Quantity", value: $editedRecipe.ingredients[index].quantity, formatter: NumberFormatter())
                            Picker("Unit", selection: $editedRecipe.ingredients[index].unit) {
                                ForEach(Unit.allCases, id: \.self) { unit in
                                    Text(unit.rawValue).tag(unit)
                                }
                            }
                        }
                    }
                    .onDelete(perform: deleteIngredient)
                    Button(action: addIngredient) {
                        Text("Add Ingredient")
                    }
                }

                Section(header: Text("Instructions")) {
                    ForEach(editedRecipe.instructions.indices, id: \.self) { index in
                        TextField("Step \(index + 1)", text: $editedRecipe.instructions[index])
                    }
                    .onDelete(perform: deleteInstruction)
                    Button(action: addInstruction) {
                        Text("Add Instruction")
                    }
                }

                Section(header: Text("Additional Information")) {
                    TextField("Prep Time (minutes)", value: $editedRecipe.prepTime, formatter: NumberFormatter())
                    TextField("Cook Time (minutes)", value: $editedRecipe.cookTime, formatter: NumberFormatter())
                    TextField("Calories", value: $editedRecipe.calories, formatter: NumberFormatter())
                    TextField("Servings", value: $editedRecipe.servings, formatter: NumberFormatter())
                    TextField("Description", text: $editedRecipe.description)
                }
            }
            .navigationBarTitle("Edit Recipe", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveRecipe()
                }
            )
        }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Recipe Update"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                loadExistingImage()
            }
        }
    }

    private func loadExistingImage() {
        print("Loading existing image from URL: \(editedRecipe.image)")
        self.imageUrl = editedRecipe.image
        if let url = URL(string: editedRecipe.image) {
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let error = error {
                    print("Error loading image: \(error.localizedDescription)")
                } else if let data = data, let uiImage = UIImage(data: data) {
                    DispatchQueue.main.async {
                        print("Image loaded successfully")
                        self.image = uiImage
                    }
                } else {
                    print("Failed to create UIImage from data")
                }
            }.resume()
        } else {
            print("Invalid image URL")
        }
    }

    private func addIngredient() {
        let newIngredient = QuantifiedIngredient(id: UUID(), name: "", quantity: 0, unit: .gram)
        editedRecipe.ingredients.append(EditableQuantifiedIngredient(from: newIngredient))
    }

    private func deleteIngredient(at offsets: IndexSet) {
        editedRecipe.ingredients.remove(atOffsets: offsets)
    }

    private func addInstruction() {
        editedRecipe.instructions.append("")
    }

    private func deleteInstruction(at offsets: IndexSet) {
        editedRecipe.instructions.remove(atOffsets: offsets)
    }

    private func saveRecipe() {
        editedRecipe.image = imageUrl ?? editedRecipe.image
        let updatedRecipe = editedRecipe.toRecipe()
        recipeManager.updateRecipe(updatedRecipe) { result in
            switch result {
            case .success(let savedRecipe):
                self.alertMessage = "Recipe updated successfully!"
                self.showingAlert = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.presentationMode.wrappedValue.dismiss()
                }
            case .failure(let error):
                self.alertMessage = "Failed to update recipe: \(error.localizedDescription)"
                self.showingAlert = true
            }
        }
    }
}

struct EditableRecipe {
    var id: String
    var name: String
    var image: String
    var ingredients: [EditableQuantifiedIngredient]
    var instructions: [String]
    var prepTime: Int
    var cookTime: Int
    var calories: Int
    var cuisine: String
    var servings: Int
    var description: String
    var mealType: MealType
    var createdBy: User

    init(from recipe: Recipe) {
        self.id = recipe.id
        self.name = recipe.name
        self.image = recipe.image
        self.ingredients = recipe.ingredients.map { EditableQuantifiedIngredient(from: $0) }
        self.instructions = recipe.instructions
        self.prepTime = recipe.prepTime
        self.cookTime = recipe.cookTime
        self.calories = recipe.calories
        self.cuisine = recipe.cuisine
        self.servings = recipe.servings
        self.description = recipe.description ?? ""
        self.mealType = recipe.mealType
        self.createdBy = recipe.createdBy ?? User(id: "", name: "", username: "", email: "")
    }

    func toRecipe() -> Recipe {
        return Recipe(
            id: id,
            name: name,
            image: image,
            ingredients: ingredients.map { $0.toQuantifiedIngredient() },
            instructions: instructions,
            prepTime: prepTime,
            cookTime: cookTime,
            calories: calories,
            cuisine: cuisine,
            servings: servings,
            description: description,
            mealType: mealType,
            createdBy: createdBy
        )
    }
}

struct EditableQuantifiedIngredient {
    var id: UUID
    var name: String
    var quantity: Double
    var unit: Unit

    init(from ingredient: QuantifiedIngredient) {
        self.id = ingredient.id
        self.name = ingredient.name
        self.quantity = ingredient.quantity
        self.unit = ingredient.unit
    }

    func toQuantifiedIngredient() -> QuantifiedIngredient {
        return QuantifiedIngredient(id: id, name: name, quantity: quantity, unit: unit)
    }
}
