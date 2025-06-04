//
//  CookView.swift
//  MilkApp
//
//  Created by William Mulvaney on 9/25/24.
//

import SwiftUI

struct CookView: View {
    @ObservedObject var recipeManager: RecipeManager
    
    var body: some View {
        NavigationView {
            List {
                    // Pantry Section
                    PantryView()// Adjust this value as needed
                    
                    // Existing recipe list can go here
                // ...
            }
            .navigationTitle("Cook")
        }
    }
}


struct RecipeRowView: View {
    let recipe: Recipe
    
    var body: some View {
        HStack {
            // You can add an image here if your Recipe model includes an image URL
            VStack(alignment: .leading) {
                Text(recipe.name)
                    .font(.headline)
                Text("Prep time: \(recipe.prepTime) min")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct CookView_Previews: PreviewProvider {
    static var previews: some View {
        CookView(recipeManager: RecipeManager())
    }
}
