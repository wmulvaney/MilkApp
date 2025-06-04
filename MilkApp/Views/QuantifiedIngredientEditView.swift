import SwiftUI

struct QuantifiedIngredientEditView: View {
    @Binding var item: QuantifiedIngredient
    let onSave: () -> Void
    let title: String
    @Environment(\.dismiss) var dismiss
    @State private var tempName: String
    @State private var tempQuantity: Double
    @State private var tempUnit: Unit
    @State private var isEditingQuantity = false
    @State private var isEditingUnit = false
    
    let units = Unit.allCases

    init(item: Binding<QuantifiedIngredient>, onSave: @escaping () -> Void, title: String = "Edit Item") {
        _item = item
        self.onSave = onSave
        self.title = title
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
            .navigationTitle(title)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    if isValid {
                        item.name = tempName
                        item.quantity = tempQuantity
                        item.unit = tempUnit
                        onSave()
                        dismiss()
                    }
                }
                .disabled(!isValid)
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
    
    private var isValid: Bool {
        !tempName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        tempQuantity > 0 &&
        tempUnit != .unknown
    }
}
