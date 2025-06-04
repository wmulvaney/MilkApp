import SwiftUI
import Foundation

struct LoadingOverlay: View {
    @Binding var isLoading: Bool
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Processing image...")
                    .padding()
                    .background(Color.secondary.colorInvert())
                    .cornerRadius(10)
                    .shadow(radius: 10)
            }
        }
    }
}




struct AddGroceryItemView: View {
    @Binding var groceryList: [QuantifiedIngredient]
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
                    Text(unit.rawValue)
                        .foregroundColor(.gray)
                }
                
                Button("Add") {
                    if let qty = Double(quantity) {
                        groceryList.append(QuantifiedIngredient(name: name, quantity: qty, unit: unit))
                        dismiss()
                    }
                }
            }
            .navigationTitle("Add Grocery Item")
        }
        .sheet(isPresented: $isEditingUnit) {
            UnitPickerView(unit: $unit, units: Unit.allCases)
                .presentationDetents([.height(200)])
        }
    }
}



struct AmountPickerView: View {
    @Binding var amount: Double
    @Environment(\.dismiss) var dismiss
    
    let wholeNumbers = Array(0...100)
    let fractions = stride(from: 0.0, through: 0.9, by: 0.1).map { $0 }
    
    var body: some View {
        VStack {
            HStack {
                Picker("Whole", selection: Binding(
                    get: { Int(amount) },
                    set: { amount = Double($0) + amount.truncatingRemainder(dividingBy: 1) }
                )) {
                    ForEach(wholeNumbers, id: \.self) { number in
                        Text("\(number)").tag(number)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(width: 100)
                .clipped()
                
                Picker("Fraction", selection: Binding(
                    get: { amount.truncatingRemainder(dividingBy: 1) },
                    set: { amount = Double(Int(amount)) + $0 }
                )) {
                    ForEach(fractions, id: \.self) { fraction in
                        Text(String(format: "%.1f", fraction)).tag(fraction)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(width: 100)
                .clipped()
            }
            Button("Done") {
                dismiss()
            }
            .padding()
        }
    }
}

struct UnitPickerView: View {
    @Binding var unit: Unit
    let units: [Unit]
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            Picker("Unit", selection: $unit) {
                ForEach(units, id: \.self) { unit in
                    Text(unit.rawValue).tag(unit)
                }
            }
            .pickerStyle(WheelPickerStyle())
            
            Button("Done") {
                dismiss()
            }
            .padding()
        }
    }
}
