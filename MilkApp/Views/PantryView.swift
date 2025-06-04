import SwiftUI
import Combine

enum ActiveSheet: Identifiable, Equatable {
    case imagePicker
    case ingredientSelection
    case editIngredient(QuantifiedIngredient)
    
    var id: String {
        switch self {
        case .imagePicker: return "imagePicker"
        case .ingredientSelection: return "ingredientSelection"
        case .editIngredient(let ingredient): return "editIngredient-\(ingredient.id)"
        }
    }
    
    static func == (lhs: ActiveSheet, rhs: ActiveSheet) -> Bool {
        return lhs.id == rhs.id
    }
}

class PantryViewModel: ObservableObject {
    @Published var pantryDataManager = PantryDataManager.shared
    @Published var image: UIImage?
    @Published var showExtractIngredientsButton = false
    @Published var imageUrl: String?
    @Published var showingNoImageAlert = false
    @Published var extractedIngredients: [QuantifiedIngredient] = []
    @Published var selectedIngredients: Set<UUID> = []
    @Published var showingNoIngredientsAlert = false
    @Published var isLoadingImage = false
    @Published var activeSheet: ActiveSheet?
    @Published var isImagePickerDismissed = false
    @Published var shouldProcessImage = false
    @Published var isPresentingSheet = false
    @Published var isLoading = false

    private var cancellables: Set<AnyCancellable> = []

    init() {
        observePantryItems()
    }

    private func observePantryItems() {
        isLoading = true  // Start loading
        pantryDataManager.$pantryItems
            .sink { [weak self] _ in
                self?.isLoading = false  // Stop loading when items are loaded
            }
            .store(in: &cancellables)
    }

    func acceptExtractedIngredients() {
        print("Accepting extracted ingredients")
        let selectedIngredients = extractedIngredients.filter { self.selectedIngredients.contains($0.id) }
        pantryDataManager.addIngredientsToPantry(selectedIngredients)

        // Reset UI state
        image = nil
        imageUrl = nil
        showExtractIngredientsButton = false
        extractedIngredients = []
        activeSheet = nil  // Add debug print here
        print("activeSheet set to nil after accepting ingredients")
    }

    func extractIngredientsFromImage() {
        print("Starting extraction process")
        guard let imageUrl = imageUrl else {
            print("No image URL available")
            isLoadingImage = false
            return
        }

        print("Starting ingredient extraction")
        isLoadingImage = true
        
        AIService.extractIngredientsFromImage(imageUrl: imageUrl) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoadingImage = false

                switch result {
                case .success(let ingredients):
                    print("Extraction successful. Ingredients count: \(ingredients.count)")
                    if !ingredients.isEmpty {
                        self?.extractedIngredients = ingredients
                        self?.selectedIngredients = Set(ingredients.map { $0.id })
                        self?.presentIngredientSelection()
                    } else {
                        self?.showingNoIngredientsAlert = true
                    }
                case .failure(let error):
                    print("Extraction failed with error: \(error.localizedDescription)")
                    self?.showingNoIngredientsAlert = true
                }
            }
        }
    }

    private func presentIngredientSelection() {
        guard !isPresentingSheet else {
            print("Already presenting a sheet")
            return
        }

        isPresentingSheet = true  // Prevent multiple presentations
        DispatchQueue.main.async { [weak self] in
            print("Showing ingredient selection")
            self?.activeSheet = .ingredientSelection
        }
    }
}

struct PantryView: View {
    @StateObject private var viewModel = PantryViewModel()
    @State private var showingClearPantryAlert = false  // State to control the alert

    var body: some View {
        Section(header: Text("Current Pantry")) {
            if viewModel.isLoading {
                ProgressView("Loading...")  // Show a loading indicator
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                if viewModel.showExtractIngredientsButton {
                    ExtractIngredientsButton(viewModel: viewModel)
                }
                ImageUploadButton(
                    image: $viewModel.image,
                    imageUrl: $viewModel.imageUrl,
                    onUploadComplete: {
                        print("Upload complete")
                        viewModel.isImagePickerDismissed = true
                    }
                )
                .listRowInsets(EdgeInsets())
                .frame(maxWidth: .infinity)
                .cornerRadius(10)
                .onChange(of: viewModel.image) { newValue in
                    viewModel.showExtractIngredientsButton = newValue != nil
                }
                .overlay(
                    Group {
                        if viewModel.isLoadingImage {
                            ProgressView()
                                .scaleEffect(1.5)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.black.opacity(0.1))
                        }
                    }
                )

                ForEach($viewModel.pantryDataManager.pantryItems) { $item in
                    PantryItemView(
                        item: $item,
                        savePantryItems: viewModel.pantryDataManager.editPantryItem,
                        activeSheet: $viewModel.activeSheet
                    )
                }
                .onDelete { indexSet in
                    indexSet.forEach { index in
                        let id = viewModel.pantryDataManager.pantryItems[index].id
                        viewModel.pantryDataManager.removeIngredientFromPantry(id)
                    }
                }

                Button("Clear Pantry") {
                    showingClearPantryAlert = true  // Show the alert when button is tapped
                }
                .alert("Clear Pantry", isPresented: $showingClearPantryAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Clear", role: .destructive) {
                        viewModel.pantryDataManager.clearPantry()  // Call clearPantry on confirmation
                    }
                } message: {
                    Text("Are you sure you want to clear all items from the pantry?")
                }
            }
        }
        .listRowBackground(Color(.systemGray6))
        .fullScreenCover(item: $viewModel.activeSheet, onDismiss: {
            viewModel.isPresentingSheet = false  // Reset flag when dismissed
            print("Full screen cover dismissed, activeSheet set to nil")
        }) { activeSheet in
            switch activeSheet {
            case .imagePicker:
                ImagePicker(image: $viewModel.image, sourceType: .camera)
            case .ingredientSelection:
                IngredientSelectionView(
                    ingredients: viewModel.extractedIngredients,
                    selectedIngredients: $viewModel.selectedIngredients,
                    onAccept: {
                        print("Accepting ingredients")
                        viewModel.acceptExtractedIngredients()
                        viewModel.activeSheet = nil
                    },
                    onCancel: {
                        print("Cancelling ingredient selection")
                        viewModel.activeSheet = nil
                    }
                )
                .onAppear { print("Ingredient selection view appeared") }
            case .editIngredient(let ingredient):
                if let index = viewModel.pantryDataManager.pantryItems.firstIndex(where: { $0.id == ingredient.id }) {
                    PantryItemEditView(
                        item: $viewModel.pantryDataManager.pantryItems[index],
                        onSave: viewModel.pantryDataManager.editPantryItem
                    )
                }
            }
        }
        .alert("No Ingredients Found", isPresented: $viewModel.showingNoIngredientsAlert) {
            Button("OK", role: .cancel) { }
        }
        .onChange(of: viewModel.activeSheet) { newValue in
            print("Active sheet changed to: \(String(describing: newValue))")
        }
    }
}

struct PantryItemView: View {
    @Binding var item: QuantifiedIngredient
    let savePantryItems: (QuantifiedIngredient) -> Void
    @Binding var activeSheet: ActiveSheet?

    var body: some View {
        Button(action: {
            activeSheet = .editIngredient(item)
        }) {
            HStack {
                Text(item.name)
                Spacer()
                Text(String(format: "%.1f", item.quantity))
                    .frame(width: 60)
                Text(item.unit.rawValue)
                    .frame(width: 40)
            }
            .foregroundColor(.blue)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .contentShape(Rectangle())
    }
}

struct AddPantryItemView: View {
    @Binding var pantryItems: [QuantifiedIngredient]
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var quantity = ""
    @State private var unit: Unit = .unknown
    @State private var isEditingUnit = false
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Name", text: $name)
                TextField("Quantity", text: $quantity)
                    .keyboardType(.decimalPad)
                Button(action: {
                    isEditingUnit = true
                }) {
                    HStack {
                        Text("Unit")
                        Spacer()
                        Text(unit.rawValue)
                            .foregroundColor(.gray)
                    }
                }
                
                Button("Add") {
                    if let qty = Double(quantity) {
                        pantryItems.append(QuantifiedIngredient(name: name, quantity: qty, unit: unit))
                        dismiss()
                    }
                }
            }
            .navigationTitle("Add Pantry Item")
        }
        .sheet(isPresented: $isEditingUnit) {
            UnitPickerView(unit: $unit, units: Unit.allCases)
                .presentationDetents([.height(200)])
        }
    }
}

struct ExtractIngredientsButton: View {
    @ObservedObject var viewModel: PantryViewModel
    
    var body: some View {
        Button("Pull out ingredients?") {
            viewModel.extractIngredientsFromImage()
        }
        .disabled(viewModel.imageUrl == nil || viewModel.isLoadingImage)
    }
}

struct PantryItemEditView: View {
    @Binding var item: QuantifiedIngredient
    let onSave: (QuantifiedIngredient) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var tempName: String
    @State private var tempQuantity: Double
    @State private var tempUnit: Unit
    @State private var isEditingQuantity = false
    @State private var isEditingUnit = false
    
    let units = Unit.allCases

    init(item: Binding<QuantifiedIngredient>, onSave: @escaping (QuantifiedIngredient) -> Void) {
        _item = item
        self.onSave = onSave
        _tempName = State(initialValue: item.wrappedValue.name)
        _tempQuantity = State(initialValue: item.wrappedValue.quantity)
        _tempUnit = State(initialValue: item.wrappedValue.unit)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Name")) {
                    TextField("Item Name", text: $tempName)
                }

                Section(header: Text("Quantity")) {
                    Button(action: {
                        isEditingQuantity = true
                    }) {
                        Text(String(format: "%.1f", tempQuantity))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .cornerRadius(8)
                    }
                }

                Section(header: Text("Unit")) {
                    Button(action: {
                        isEditingUnit = true
                    }) {
                        Text(tempUnit.rawValue)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .cornerRadius(8)
                    }
                }
            }
            .navigationTitle("Edit Pantry Item")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    item.name = tempName
                    item.quantity = tempQuantity
                    item.unit = tempUnit
                    onSave(item)
                    dismiss()
                }
            )
        }
        .sheet(isPresented: $isEditingQuantity) {
            AmountPickerView(amount: $tempQuantity)
                .presentationDetents([.height(200)])
        }
        .sheet(isPresented: $isEditingUnit) {
            UnitPickerView(unit: $tempUnit, units: units)
                .presentationDetents([.height(200)])
        }
    }
}


struct IngredientSelectionView: View {
    @State private var ingredients: [QuantifiedIngredient]
    @Binding var selectedIngredients: Set<UUID>
    let onAccept: () -> Void
    let onCancel: () -> Void
    @Environment(\.dismiss) var dismiss
    @State private var editingIngredient: QuantifiedIngredient?

    init(ingredients: [QuantifiedIngredient], selectedIngredients: Binding<Set<UUID>>, onAccept: @escaping () -> Void, onCancel: @escaping () -> Void) {
        _ingredients = State(initialValue: ingredients)
        _selectedIngredients = selectedIngredients
        self.onAccept = onAccept
        self.onCancel = onCancel
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(ingredients) { ingredient in
                    ingredientRow(for: ingredient)
                }
            }
            .navigationTitle("Select Ingredients")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    cancelButton
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    acceptButton
                }
            }
            .interactiveDismissDisabled()
        }
        .sheet(item: $editingIngredient) { ingredient in
            NavigationView {
                editIngredientSheet(ingredient)
            }
        }
    }

    private func ingredientRow(for ingredient: QuantifiedIngredient) -> some View {
        HStack {
            Text(ingredient.name)
            Spacer()
            Text(String(format: "%.1f", ingredient.quantity))
                .frame(width: 60)
            Text(ingredient.unit.rawValue)
                .frame(width: 40)
            selectionButton(for: ingredient.id)
        }
        .foregroundColor(selectedIngredients.contains(ingredient.id) ? .blue : .gray)
        .contentShape(Rectangle())
        .onTapGesture {
            editingIngredient = ingredient
        }
    }

    private func selectionButton(for id: UUID) -> some View {
        Button(action: {
            toggleSelection(for: id)
        }) {
            Image(systemName: selectedIngredients.contains(id) ? "checkmark.circle.fill" : "circle")
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func toggleSelection(for id: UUID) {
        if selectedIngredients.contains(id) {
            selectedIngredients.remove(id)
        } else {
            selectedIngredients.insert(id)
        }
    }

    private var cancelButton: some View {
        Button("Cancel") {
            onCancel()
            dismiss()
        }
    }

    private var acceptButton: some View {
        Button("Accept") {
            onAccept()
            dismiss()
        }
    }

    @ViewBuilder
    private func editIngredientSheet(_ ingredient: QuantifiedIngredient) -> some View {
        PantryItemEditView(
            item: Binding(
                get: { 
                    QuantifiedIngredient(id: ingredient.id, name: ingredient.name, quantity: Double(ingredient.quantity) ?? 0, unit: ingredient.unit)
                },
                set: { newItem in
                    updateIngredient(newItem, for: ingredient.id)
                }
            ),
            onSave: { updatedIngredient in
                updateIngredient(updatedIngredient, for: ingredient.id)
                editingIngredient = nil
            }
        )
    }

    private func updateIngredient(_ newItem: QuantifiedIngredient, for id: UUID) {
        if let index = ingredients.firstIndex(where: { $0.id == id }) {
            ingredients[index] = newItem
        }
    }
}


