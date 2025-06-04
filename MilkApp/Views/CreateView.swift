import SwiftUI

class CreateViewModel: ObservableObject {
    @Published var recipeName = ""
    @Published var ingredients: [QuantifiedIngredient] = [QuantifiedIngredient(name: "", quantity: 0, unit: .unknown)]
    @Published var instructions: [String] = [""]
    @Published var image: UIImage?
    @Published var imageUrl: String?
    @Published var showingImagePicker = false
    @Published var prepTime = ""
    @Published var cookTime = ""
    @Published var calories = ""
    @Published var cuisine = ""
    @Published var servings = ""
    @Published var showingAlert = false
    @Published var alertMessage = ""
    @Published var createdRecipe: Recipe?
    @Published var showingRecipeDetail = false
    @Published var description = ""
    @Published var mealType: MealType = .unknown
    @Published var imagePickerSourceType: UIImagePickerController.SourceType = .camera
    @Published var isEditingUnit = false
    @Published var editingIngredientIndex: Int?
    @Published var isEditingIngredient = false
    @Published var tempIngredient: QuantifiedIngredient?
    let units = Unit.allCases
}

struct CreateView: View {
    @StateObject private var viewModel = CreateViewModel()
    @ObservedObject var recipeManager: RecipeManager
    let userId: String
    @Binding var isPresented: Bool

    @State private var showingCreateRecipe = false
    @State private var showingCreateRecipeBook = false

    var body: some View {
        ZStack {
            VStack {
                Spacer()
            }

            // Overlay with buttons
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    isPresented = false
                }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack {
                        Button(action: {
                            showingCreateRecipe = true
                        }) {
                            Image(systemName: "doc.text.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.green)
                                .padding()
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                        .padding(.bottom, 10)

                        Button(action: {
                            showingCreateRecipeBook = true
                        }) {
                            Image(systemName: "book.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.orange)
                                .padding()
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                    }
                    .padding(.trailing, 20)
                }
            }
        }
        .sheet(isPresented: $showingCreateRecipe) {
            CreateRecipeView(recipeManager: recipeManager, userId: userId)
        }
        .sheet(isPresented: $showingCreateRecipeBook) {
            CreateRecipeBookView()
        }
    }
}
