import SwiftUI

class CreateRecipeViewModel: ObservableObject {
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
    @Published var currentStep: CreateStep = .camera
    @Published var imagePickerSourceType: UIImagePickerController.SourceType = .camera
    @Published var isEditingUnit = false
    @Published var editingIngredientIndex: Int?
    @Published var isEditingIngredient = false
    @Published var tempIngredient: QuantifiedIngredient?
    let units = Unit.allCases
}

enum CreateStep {
    case camera
    case fullScreenImage
    case titleAndDescription
    case ingredients
    case instructions
    case additionalInfo
    case details
}

struct CreateRecipeView: View {
    @StateObject private var viewModel = CreateRecipeViewModel()
    @ObservedObject var recipeManager: RecipeManager
    let userId: String
    @Environment(\.presentationMode) var presentationMode
    @State private var showingCancelAlert = false

    var body: some View {
        ZStack {
            switch viewModel.currentStep {
            case .camera:
                CameraView()
            case .fullScreenImage:
                FullScreenImageView()
            case .titleAndDescription:
                TitleAndDescriptionView()
            case .ingredients:
                IngredientsView()
            case .instructions:
                InstructionsView()
            case .additionalInfo:
                AdditionalInfoView()
            case .details:
                RecipeDetailsView()
            }

            VStack {
                HStack {
                    Button(action: {
                        showingCancelAlert = true
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .padding(.leading, 10)
                    Spacer()
                }
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $viewModel.showingImagePicker) {
            ImagePicker(image: $viewModel.image, sourceType: viewModel.imagePickerSourceType)
        }
        .alert(isPresented: $viewModel.showingAlert) {
            Alert(title: Text("Recipe Creation"), message: Text(viewModel.alertMessage), dismissButton: .default(Text("OK")))
        }
        .sheet(item: $viewModel.createdRecipe) { recipe in
            RecipeDetailView(recipe: recipe, recipeManager: recipeManager)
        }
        .alert(isPresented: $showingCancelAlert) {
            Alert(
                title: Text("Cancel Recipe Creation"),
                message: Text("Are you sure you want to discard this recipe? Your progress will be lost."),
                primaryButton: .destructive(Text("Discard")) {
                    presentationMode.wrappedValue.dismiss()
                },
                secondaryButton: .cancel()
            )
        }
        .sheet(isPresented: $viewModel.isEditingUnit) {
            if let index = viewModel.editingIngredientIndex {
                UnitPickerView(unit: $viewModel.ingredients[index].unit, units: Unit.allCases)
                    .presentationDetents([.height(200)])
            }
        }
        .sheet(isPresented: $viewModel.isEditingIngredient) {
            if let index = viewModel.editingIngredientIndex {
                QuantifiedIngredientEditView(
                    item: Binding(
                        get: { index < viewModel.ingredients.count ? viewModel.ingredients[index] : QuantifiedIngredient(name: "", quantity: 0, unit: .unknown) },
                        set: { newValue in
                            if index < viewModel.ingredients.count {
                                viewModel.ingredients[index] = newValue
                            } else {
                                viewModel.ingredients.append(newValue)
                            }
                        }
                    ),
                    onSave: {
                        viewModel.editingIngredientIndex = nil
                        viewModel.isEditingIngredient = false
                    },
                    title: index == viewModel.ingredients.count ? "Add Ingredient" : "Edit Ingredient"
                )
            }
        }
    }


    @ViewBuilder
    private func CameraView() -> some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            VStack {
                Spacer()
                HStack(spacing: 50) {
                    Button(action: {
                        viewModel.showingImagePicker = true
                        viewModel.imagePickerSourceType = .photoLibrary
                    }) {
                        VStack {
                            Image(systemName: "photo.on.rectangle")
                                .font(.largeTitle)
                                .padding()
                                .background(Color.white)
                                .clipShape(Circle())
                            Text("Photos")
                                .foregroundColor(.white)
                        }
                    }
                    
                    Button(action: {
                        viewModel.showingImagePicker = true
                        viewModel.imagePickerSourceType = .camera
                    }) {
                        VStack {
                            Image(systemName: "camera")
                                .font(.largeTitle)
                                .padding()
                                .background(Color.white)
                                .clipShape(Circle())
                            Text("Camera")
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .sheet(isPresented: $viewModel.showingImagePicker) {
            ImagePicker(image: $viewModel.image, sourceType: viewModel.imagePickerSourceType)
        }
        .onChange(of: viewModel.image) { _ in
            if viewModel.image != nil {
                viewModel.currentStep = .fullScreenImage
            }
        }
    }

    @ViewBuilder
    private func FullScreenImageView() -> some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            if let image = viewModel.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .edgesIgnoringSafeArea(.all)
            }
            
            VStack {
                Spacer()
                
                HStack {
                    Button(action: {
                        viewModel.currentStep = .camera
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Different Image")
                        }
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.currentStep = .titleAndDescription
                    }) {
                        HStack {
                            Text("Next")
                            Image(systemName: "chevron.right")
                        }
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding()
                        .frame(minWidth: 100)
                        .background(Color.white)
                        .cornerRadius(10)
                    }
                }
                .padding()
            }
        }
    }

    @ViewBuilder
    private func TitleAndDescriptionView() -> some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.black, Color(hex: "#DF2E2E").opacity(0.8)]),
                           startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
        
        VStack(spacing: 0) {
            ScrollView {
                Spacer(minLength: 50)
                
                VStack(alignment: .leading, spacing: 20) {
                    Text("Recipe Name")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    TextField("Enter recipe name", text: $viewModel.recipeName)
                        .font(.title2)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(15)
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                        .padding(.horizontal)
                    
                    Text("Description")
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .padding(.top, 10)
                    
                    TextEditor(text: $viewModel.description)
                        .font(.body)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(15)
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                        .frame(height: 150)
                        .padding(.horizontal)
                }
                .padding(.top, 20)
            }
            
            Spacer(minLength: 10)
            
            HStack {
                Button(action: {
                    viewModel.currentStep = .fullScreenImage
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.7))
                    .cornerRadius(15)
                    .shadow(radius: 5)
                }
                
                Spacer().frame(width: 20)
                
                Button(action: {
                    viewModel.currentStep = .ingredients
                }) {
                    HStack {
                        Text("Next")
                        Image(systemName: "chevron.right")
                    }
                    .font(.headline)
                    .foregroundColor(viewModel.recipeName.isEmpty ? .gray : .white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(viewModel.recipeName.isEmpty ? Color.gray.opacity(0.5) : Color(hex: "#BCEFFF"))
                    .cornerRadius(15)
                    .shadow(radius: 5)
                }
                .disabled(viewModel.recipeName.isEmpty)
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 20)
        }
    }
}


    @ViewBuilder
    private func IngredientsView() -> some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.black, Color(hex: "#DF2E2E").opacity(0.8)]),
                           startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                ScrollView {
                    Spacer(minLength: 50)
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Ingredients")
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        ForEach(Array(viewModel.ingredients.enumerated()), id: \.element.id) { index, ingredient in
                            HStack(alignment: .center, spacing: 10) {
                                Text("\(index + 1).")
                                    .foregroundColor(.white)
                                    .frame(width: 30, alignment: .trailing)
                                
                                TextField("Ingredient", text: $viewModel.ingredients[index].name)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(15)
                                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                                
                                NumberPickerView(
                                    title: ingredient.quantity == 0 ? "Amount" : nil,
                                    value: Binding(
                                        get: { String(format: "%.1f", viewModel.ingredients[index].quantity) },
                                        set: { viewModel.ingredients[index].quantity = Double($0) ?? 0 }
                                    ),
                                    range: 0...999.9,
                                    unit: viewModel.ingredients[index].unit.rawValue,
                                    allowsDecimals: true,
                                    startAtTens: false
                                )
                                .frame(width: 120)
                                .background(Color(.systemGray6))
                                .cornerRadius(15)
                                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                                
                                Button(action: {
                                    viewModel.editingIngredientIndex = index
                                    viewModel.isEditingUnit = true
                                }) {
                                    Text(viewModel.ingredients[index].unit == .unknown ? "Unit" : viewModel.ingredients[index].unit.rawValue)
                                        .foregroundColor(viewModel.ingredients[index].unit == .unknown ? .gray : .black)
                                        .padding(8)
                                        .frame(width: 60)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(15)
                                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                                }
                                
                                if viewModel.ingredients.count > 1 {
                                    Button(action: {
                                        deleteIngredient(at: IndexSet(integer: index))
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                            .padding(8)
                                            .background(Color(.systemGray6))
                                            .cornerRadius(15)
                                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        Button(action: {
                            viewModel.ingredients.append(QuantifiedIngredient(name: "", quantity: 0, unit: .unknown))
                        }) {
                            Text("Add Ingredient")
                                .foregroundColor(.blue)
                                .padding(.vertical, 10)
                        }
                    }
                    .padding()
                }
                
                Spacer(minLength: 20)
                
                HStack {
                    Spacer()
                    Button(action: {
                        viewModel.currentStep = .titleAndDescription
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                    }
                    
                    Spacer(minLength: 40)
                    
                    Button(action: {
                        viewModel.currentStep = .instructions
                    }) {
                        HStack {
                            Text("Next")
                            Image(systemName: "chevron.right")
                        }
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding()
                        .frame(minWidth: 100)
                        .background(areAllIngredientsValid ? Color.white : Color.gray)
                        .cornerRadius(10)
                    }
                    .disabled(!areAllIngredientsValid)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $viewModel.isEditingUnit) {
            if let index = viewModel.editingIngredientIndex {
                UnitPickerView(unit: $viewModel.ingredients[index].unit, units: Unit.allCases)
                    .presentationDetents([.height(200)])
            }
        }
    }

    private var areAllIngredientsValid: Bool {
        !viewModel.ingredients.isEmpty && viewModel.ingredients.allSatisfy { ingredient in
            !ingredient.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            ingredient.quantity > 0 &&
            ingredient.unit != .unknown
        }
    }

    @ViewBuilder
    private func InstructionsView() -> some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                ScrollView {
                    Spacer(minLength: 50)
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Instructions")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        ForEach(Array(viewModel.instructions.enumerated()), id: \.offset) { index, _ in
                            HStack(alignment: .center, spacing: 10) {
                                Text("\(index + 1).")
                                    .foregroundColor(.white)
                                    .frame(width: 30, alignment: .trailing)
                                
                                TextField("Instruction", text: $viewModel.instructions[index])
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .padding(8)
                                    .background(Color.white)
                                    .cornerRadius(8)
                            }
                        }
                        .onDelete(perform: deleteInstruction)
                        
                        Button(action: addInstruction) {
                            Text("Add Instruction")
                                .foregroundColor(.blue)
                                .padding(.vertical, 10)
                        }
                    }
                    .padding()
                }
                
                Spacer(minLength: 20)
                
                HStack {
                    Spacer()
                    Button(action: {
                        viewModel.currentStep = .ingredients
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                    }
                    
                    Spacer(minLength: 40)
                    
                    Button(action: {
                        viewModel.currentStep = .additionalInfo
                    }) {
                        HStack {
                            Text("Next")
                            Image(systemName: "chevron.right")
                        }
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding()
                        .frame(minWidth: 100)
                        .background(viewModel.instructions.isEmpty ? Color.gray : Color.white)
                        .cornerRadius(10)
                    }
                    .disabled(viewModel.instructions.isEmpty)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }

    private func addInstruction() {
        viewModel.instructions.append("")
    }

    private func deleteInstruction(at offsets: IndexSet) {
        viewModel.instructions.remove(atOffsets: offsets)
        if viewModel.instructions.isEmpty {
            viewModel.instructions = [""]
        }
    }

    @ViewBuilder
    private func AdditionalInfoView() -> some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                ScrollView {
                    Spacer(minLength: 50)
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Additional Information")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Group {
                            TextField("Description", text: $viewModel.description)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding(8)
                                .background(Color.white)
                                .cornerRadius(8)
                            
                            NumberPickerView(title: "Prep Time", value: $viewModel.prepTime, range: 1...180, unit: "min", allowsDecimals: false, startAtTens: false)
                            NumberPickerView(title: "Cook Time", value: $viewModel.cookTime, range: 1...480, unit: "min", allowsDecimals: false, startAtTens: false)
                            NumberPickerView(title: "Calories", value: $viewModel.calories, range: 1...2000, unit: "cal", allowsDecimals: false, startAtTens: true)
                            
                            TextField("Cuisine", text: $viewModel.cuisine)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding(8)
                                .background(Color.white)
                                .cornerRadius(8)
                            
                            NumberPickerView(title: "Servings", value: $viewModel.servings, range: 1...20, unit: "", allowsDecimals: false, startAtTens: false)
                            
                            Picker("Meal Type", selection: $viewModel.mealType) {
                                ForEach(MealType.allCases, id: \.self) { mealType in
                                    Text(mealType.rawValue).tag(mealType)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding(8)
                            .background(Color.white)
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                }
                
                Spacer(minLength: 20)
                
                HStack {
                    Spacer()
                    Button(action: {
                        viewModel.currentStep = .instructions
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                    }
                    
                    Spacer(minLength: 40)
                    
                    Button(action: {
                        viewModel.currentStep = .details
                    }) {
                        HStack {
                            Text("Next")
                            Image(systemName: "chevron.right")
                        }
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding()
                        .frame(minWidth: 100)
                        .background(Color.white)
                        .cornerRadius(10)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }

    struct NumberPickerView: View {
        let title: String?
        @Binding var value: String
        let range: ClosedRange<Double>
        let unit: String
        let allowsDecimals: Bool
        let startAtTens: Bool
        @State private var isPresented = false
        
        var body: some View {
            Button(action: {
                isPresented = true
            }) {
                HStack {
                    if let title = title {
                        Text(title)
                        Spacer()
                    }
                    Text("\(value) \(unit)").foregroundColor(.gray)
                }
                .padding(8)
                .background(Color.white)
                .cornerRadius(8)
            }
            .sheet(isPresented: $isPresented) {
                VStack {
                    HStack {
                        Spacer()
                        Button("Done") {
                            isPresented = false
                        }
                        .padding()
                    }
                    DynamicNumberPicker(
                        value: Binding(
                            get: { Double(value) ?? range.lowerBound },
                            set: { value = String(format: allowsDecimals ? "%.1f" : "%.0f", $0) }
                        ),
                        range: range,
                        allowsDecimals: allowsDecimals,
                        startAtTens: startAtTens
                    )
                    Text(unit)
                        .font(.headline)
                        .padding(.top)
                }
                .presentationDetents([.height(250)])
                .presentationDragIndicator(.visible)
            }
        }
    }

    struct DynamicNumberPicker: View {
        @Binding var value: Double
        let range: ClosedRange<Double>
        let allowsDecimals: Bool
        let startAtTens: Bool
        
        var body: some View {
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    if range.upperBound >= 100 {
                        Picker("Hundreds", selection: hundredsBinding) {
                            ForEach(0...9, id: \.self) { i in
                                Text("\(i)").tag(i)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: geometry.size.width / 3)
                        .clipped()
                    }
                    
                    if range.upperBound >= 10 {
                        Picker("Tens", selection: tensBinding) {
                            ForEach(0...9, id: \.self) { i in
                                Text("\(i)").tag(i)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: geometry.size.width / 3)
                        .clipped()
                    }
                    
                    Picker("Ones", selection: onesBinding) {
                        ForEach(0...9, id: \.self) { i in
                            Text("\(i)").tag(i)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(width: geometry.size.width / 3)
                    .clipped()
                    
                    if allowsDecimals {
                        Picker("Tenths", selection: tenthsBinding) {
                            ForEach(0...9, id: \.self) { i in
                                Text(".\(i)").tag(i)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: geometry.size.width / 3)
                        .clipped()
                    }
                }
            }
        }
        
        private var hundredsBinding: Binding<Int> {
            Binding<Int>(
                get: { Int(value) / 100 },
                set: { newValue in
                    let current = Int(value)
                    value = Double(newValue * 100 + current % 100) + value.truncatingRemainder(dividingBy: 1)
                }
            )
        }
        
        private var tensBinding: Binding<Int> {
            Binding<Int>(
                get: { (Int(value) / 10) % 10 },
                set: { newValue in
                    let current = Int(value)
                    value = Double((current / 100) * 100 + newValue * 10 + current % 10) + value.truncatingRemainder(dividingBy: 1)
                }
            )
        }
        
        private var onesBinding: Binding<Int> {
            Binding<Int>(
                get: { Int(value) % 10 },
                set: { newValue in
                    let current = Int(value)
                    value = Double((current / 10) * 10 + newValue) + value.truncatingRemainder(dividingBy: 1)
                }
            )
        }
        
        private var tenthsBinding: Binding<Int> {
            Binding<Int>(
                get: { Int((value.truncatingRemainder(dividingBy: 1)) * 10) },
                set: { value = Double(Int(value)) + Double($0) / 10 }
            )
        }
    }

    @ViewBuilder
    private func RecipeDetailsView() -> some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Spacer()
                Text("Review Recipe")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding()
            .background(Color.black.opacity(0.6))
            
            // Form Content
            FormContent()
            
            // Save Button
            SaveButton()
        }
    }

    @ViewBuilder
    private func FormContent() -> some View {
        Form {
            RecipeNameSection()
            ImageSection()
            IngredientsSection()
            InstructionsSection()
            AdditionalInfoSection()
        }
        .background(Color.clear)
        .toolbar {
            EditButton()
        }
    }

    private func RecipeNameSection() -> some View {
        Section(header: Text("Recipe Name")) {
            TextField("Enter recipe name", text: $viewModel.recipeName)
        }
        .listRowBackground(Color(.systemGray6))
    }

    private func ImageSection() -> some View {
        Section(header: Text("Image")) {
            ImageUploadButton(image: $viewModel.image, imageUrl: $viewModel.imageUrl)
                .listRowInsets(EdgeInsets())
                .frame(maxWidth: .infinity)
        }
    }

    private func IngredientsSection() -> some View {
        Section(header: Text("Ingredients")) {
            ForEach(viewModel.ingredients.indices, id: \.self) { index in
                HStack {
                    Text("\(index + 1).")
                        .frame(width: 25, alignment: .leading)
                    Text(viewModel.ingredients[index].name)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    Text("\(String(format: "%.1f", viewModel.ingredients[index].quantity)) \(viewModel.ingredients[index].unit.rawValue)")
                        .frame(width: 80, alignment: .trailing)
                    Button(action: {
                        editIngredient(at: index)
                    }) {
                        Image(systemName: "pencil")
                            .foregroundColor(.blue)
                    }
                }
            }
            .onDelete(perform: deleteIngredient)
            
            Button(action: addIngredient) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Ingredient")
                }
            }
        }
        .listRowBackground(Color(.systemGray6))
    }

    private func addIngredient() {
        viewModel.editingIngredientIndex = viewModel.ingredients.count
        viewModel.isEditingIngredient = true
    }

    private func editIngredient(at index: Int) {
        viewModel.editingIngredientIndex = index
        viewModel.isEditingIngredient = true
    }

    private func deleteIngredient(at offsets: IndexSet) {
        viewModel.ingredients.remove(atOffsets: offsets)
    }

    private func InstructionsSection() -> some View {
        Section(header: Text("Instructions")) {
            ForEach(viewModel.instructions.indices, id: \.self) { index in
                HStack(alignment: .top) {
                    Text("\(index + 1).")
                        .frame(width: 25, alignment: .leading)
                    TextField("Step \(index + 1)", text: $viewModel.instructions[index])
                    Spacer()
                    Image(systemName: "line.3.horizontal")
                        .foregroundColor(.gray)
                }
            }
            .onMove(perform: moveInstruction)
            .onDelete(perform: deleteInstruction)
            .moveDisabled(false)
            
            if !viewModel.instructions.isEmpty && !viewModel.instructions.last!.isEmpty {
                Button(action: addInstruction) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Step")
                    }
                }
            }
        }
        .listRowBackground(Color(.systemGray6))
    }

    private func moveInstruction(from source: IndexSet, to destination: Int) {
        viewModel.instructions.move(fromOffsets: source, toOffset: destination)
    }

    private func AdditionalInfoSection() -> some View {
        Section(header: Text("Additional Information")) {
            TextField("Description", text: $viewModel.description)
                .frame(height: 100)
            TextField("Prep Time (minutes)", text: $viewModel.prepTime)
                .keyboardType(.numberPad)
            TextField("Cook Time (minutes)", text: $viewModel.cookTime)
                .keyboardType(.numberPad)
            TextField("Calories", text: $viewModel.calories)
                .keyboardType(.numberPad)
            TextField("Cuisine", text: $viewModel.cuisine)
            TextField("Servings", text: $viewModel.servings)
                .keyboardType(.numberPad)
            Picker("Meal Type", selection: $viewModel.mealType) {
                ForEach(MealType.allCases, id: \.self) { mealType in
                    Text(mealType.rawValue).tag(mealType)
                }
            }
        }
        .listRowBackground(Color(.systemGray6))
    }

    private func SaveButton() -> some View {
        Button(action: saveRecipe) {
            Text("Save Recipe")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .padding()
    }

    private func saveRecipe() {
        guard !viewModel.recipeName.isEmpty,
              !viewModel.ingredients.isEmpty,
              viewModel.ingredients.allSatisfy({ !$0.name.isEmpty && $0.quantity > 0 }),
              !viewModel.instructions.isEmpty,
              let prepTimeInt = Int(viewModel.prepTime),
              let cookTimeInt = Int(viewModel.cookTime),
              let caloriesInt = Int(viewModel.calories),
              let servingsInt = Int(viewModel.servings) else {
            viewModel.alertMessage = "Please fill in all fields correctly"
            viewModel.showingAlert = true
            return
        }
        
        if let url = viewModel.imageUrl {
            viewModel.imageUrl = url
        } else {
            viewModel.imageUrl = ""  // Or use a default image URL
        }
        
        let newRecipe = Recipe(
            id: "",
            name: viewModel.recipeName,
            image: viewModel.imageUrl ?? "",
            ingredients: viewModel.ingredients,
            instructions: viewModel.instructions.filter { !$0.isEmpty },
            prepTime: prepTimeInt,
            cookTime: cookTimeInt,
            calories: caloriesInt,
            cuisine: viewModel.cuisine,
            servings: servingsInt,
            description: viewModel.description.isEmpty ? "" : viewModel.description,
            mealType: viewModel.mealType,
            createdBy: AuthenticationService.shared.currentUser ?? User(id: "", name: nil, username: "", email: "", profileImage: nil)
        )
        
        print("Sending recipe to server: \(newRecipe)")
        
        AuthenticationService.shared.addRecipe(recipe: newRecipe) { success, message, recipeId in
            DispatchQueue.main.async {
                if success {
                    print("Recipe created successfully. ID: \(recipeId ?? "N/A")")
                    if let id = recipeId {
                        let createdRecipeWithId = Recipe(
                            id: id,
                            name: newRecipe.name,
                            image: newRecipe.image,
                            ingredients: newRecipe.ingredients,
                            instructions: newRecipe.instructions,
                            prepTime: newRecipe.prepTime,
                            cookTime: newRecipe.cookTime,
                            calories: newRecipe.calories,
                            cuisine: newRecipe.cuisine,
                            servings: newRecipe.servings,
                            description: newRecipe.description ?? "",
                            mealType: newRecipe.mealType ?? .unknown,
                            createdBy: AuthenticationService.shared.currentUser ?? User(id: "", name: nil, username: "", email: "", profileImage: nil)
                        )
                        self.viewModel.createdRecipe = createdRecipeWithId
                        self.viewModel.showingRecipeDetail = true
                        self.clearForm()
                        
                        // Post notification to refresh recipes
                        NotificationCenter.default.post(name: .refreshRecipes, object: nil)
                    } else {
                        self.viewModel.alertMessage = "Recipe created but no ID returned"
                        self.viewModel.showingAlert = true
                    }
                } else {
                    print("Failed to add recipe. Message: \(message ?? "No message")")
                    self.viewModel.alertMessage = message ?? "Failed to add recipe"
                    self.viewModel.showingAlert = true
                }
            }
        }
    }
    
    private func clearForm() {
        viewModel.recipeName = ""
        viewModel.ingredients = []
        viewModel.instructions = [""]
        viewModel.prepTime = ""
        viewModel.cookTime = ""
        viewModel.calories = ""
        viewModel.cuisine = ""
        viewModel.servings = ""
        viewModel.image = nil
        viewModel.imageUrl = nil
        viewModel.description = ""
        viewModel.mealType = .unknown
        print("Form data cleared")
    }
}

// Add this extension for hex color support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
