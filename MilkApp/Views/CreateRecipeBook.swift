import SwiftUI

class CreateRecipeBookViewModel: ObservableObject {
    @Published var title = ""
    @Published var description = ""
    @Published var coverImage: UIImage?
    @Published var showingImagePicker = false
    @Published var alertMessage = ""
    @Published var showingAlert = false
}

struct CreateRecipeBookView: View {
    @StateObject private var viewModel = CreateRecipeBookViewModel()
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            TextField("Title", text: $viewModel.title)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)

            TextEditor(text: $viewModel.description)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)

            Button(action: {
                viewModel.showingImagePicker = true
            }) {
                Text("Select Cover Image")
            }
            .padding()

            Button(action: createRecipeBook) {
                Text("Create Recipe Book")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()

            Spacer()
        }
        .sheet(isPresented: $viewModel.showingImagePicker) {
            ImagePicker(image: $viewModel.coverImage, sourceType: .photoLibrary)
        }
        .alert(isPresented: $viewModel.showingAlert) {
            Alert(title: Text("Create Recipe Book"), message: Text(viewModel.alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    private func createRecipeBook() {
        guard !viewModel.title.isEmpty else {
            viewModel.alertMessage = "Title is required"
            viewModel.showingAlert = true
            return
        }

        // Convert UIImage to a URL or base64 string if needed
        let coverImageUrl = "" // Implement image upload logic or conversion here

        let newRecipeBook = RecipeBook(
            id: UUID().uuidString,  // Generate a temporary ID
            author: AuthenticationService.shared.currentUser ?? User(id: "", name: nil, username: "", email: "", profileImage: nil),
            title: viewModel.title,
            description: viewModel.description,
            dateCreated: Date(),
            coverImage: coverImageUrl,
            recipes: []
        )

        UserService.shared.createRecipeBook(recipeBook: newRecipeBook) { success, errorMessage in
            DispatchQueue.main.async {
                if success {
                    viewModel.alertMessage = "Recipe book created successfully"
                    viewModel.showingAlert = true
                } else {
                    viewModel.alertMessage = "Failed to create recipe book: \(errorMessage ?? "")"
                    viewModel.showingAlert = true
                }
            }
        }
    }
} 