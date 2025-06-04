import SwiftUI

struct AddItemButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text(title)
            }
        }
        .foregroundColor(.blue)
    }
}