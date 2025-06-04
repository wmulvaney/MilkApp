import Foundation
import SwiftUI

let sampleRecipes: [Recipe] = [
    Recipe(
        id: "1",
        name: "Spaghetti Carbonara",
        image: "https://imgs.search.brave.com/Aqyck6KGW7GjY4a_4nogz0H2B1kTCQi2QbnBzwYNyJs/rs:fit:500:0:0:0/g:ce/aHR0cHM6Ly90My5m/dGNkbi5uZXQvanBn/LzA4LzE1LzM4LzUw/LzM2MF9GXzgxNTM4/NTA4N18xeUFac3JC/aDFMTk1FaXVQMVdQ/NWlaS2pQdTdFbjFH/by5qcGc",
        ingredients: [
            QuantifiedIngredient(name: "spaghetti", quantity: 200, unit: .gram),
            QuantifiedIngredient(name: "pancetta", quantity: 100, unit: .gram),
            QuantifiedIngredient(name: "large eggs", quantity: 2, unit: .each),
            QuantifiedIngredient(name: "pecorino cheese", quantity: 50, unit: .gram),
            QuantifiedIngredient(name: "parmesan", quantity: 50, unit: .gram),
            QuantifiedIngredient(name: "black pepper", quantity: 1, unit: .toTaste)
        ],
        instructions: [
            "Cook pasta in salted water",
            "Fry pancetta until crispy",
            "Beat eggs with cheese and pepper",
            "Mix pasta with pancetta, then add egg mixture"
        ],
        prepTime: 10,
        cookTime: 15,
        calories: 450,
        cuisine: "Italian",
        servings: 2,
        description: "A classic Italian pasta dish with a creamy egg sauce, crispy pancetta, and a generous amount of cheese.",
        mealType: .dinner,
        createdBy: User(id: "2", name: "John Doe", username: "john_doe", email: "john.doe@example.com", profileImage: "https://imgs.search.brave.com/Aqyck6KGW7GjY4a_4nogz0H2B1kTCQi2QbnBzwYNyJs/rs:fit:500:0:0:0/g:ce/aHR0cHM6Ly90My5m/dGNkbi5uZXQvanBn/LzA4LzE1LzM4LzUw/LzM2MF9GXzgxNTM4/NTA4N18xeUFac3JC/aDFMTk1FaXVQMVdQ/NWlaS2pQdTdFbjFH/by5qcGc")
    ),
    Recipe(
        id: "2",
        name: "Chicken Stir Fry",
        image: "https://imgs.search.brave.com/GryvvlCTuGYAeEdsnlABws59j90Jz7ebeFEvW9-hxLc/rs:fit:500:0:0:0/g:ce/aHR0cHM6Ly93d3cu/YnVkZ2V0Ynl0ZXMu/Y29tL3dwLWNvbnRl/bnQvdXBsb2Fkcy8y/MDI0LzAxL0NoaWNr/ZW4tU3Rpci1Gcnkt/VjEuanBlZw",
        ingredients: [
            QuantifiedIngredient(name: "chicken breast", quantity: 500, unit: .gram),
            QuantifiedIngredient(name: "bell pepper", quantity: 1, unit: .each),
            QuantifiedIngredient(name: "onion", quantity: 1, unit: .each),
            QuantifiedIngredient(name: "garlic cloves", quantity: 2, unit: .each),
            QuantifiedIngredient(name: "soy sauce", quantity: 2, unit: .tablespoon),
            QuantifiedIngredient(name: "vegetable oil", quantity: 2, unit: .tablespoon)
        ],
        instructions: [
            "Cut chicken and vegetables",
            "Heat oil in a wok",
            "Stir fry chicken until cooked",
            "Add vegetables and stir fry",
            "Add soy sauce and serve"
        ],
        prepTime: 15,
        cookTime: 10,
        calories: 300,
        cuisine: "Asian",
        servings: 4,
        description: "A quick and healthy Asian-inspired dish featuring tender chicken and crisp vegetables in a savory sauce.",
        mealType: .dinner,
        createdBy: User(id: "2", name: "John Doe", username: "john_doe", email: "john.doe@example.com", profileImage: "https://imgs.search.brave.com/Aqyck6KGW7GjY4a_4nogz0H2B1kTCQi2QbnBzwYNyJs/rs:fit:500:0:0:0/g:ce/aHR0cHM6Ly90My5m/dGNkbi5uZXQvanBn/LzA4LzE1LzM4LzUw/LzM2MF9GXzgxNTM4/NTA4N18xeUFac3JC/aDFMTk1FaXVQMVdQ/NWlaS2pQdTdFbjFH/by5qcGc")
    ),
    Recipe(
        id: "3",
        name: "Caesar Salad",
        image: "https://imgs.search.brave.com/oOUwT62pseYKNS4_bMhGVwtLp9nh2EgWZ9VPW_leuro/rs:fit:500:0:0:0/g:ce/aHR0cHM6Ly9pbWcu/ZnJlZXBpay5jb20v/cHJlbWl1bS1waG90/by9jYWVzYXItc2Fs/YWQtd2l0aC1mcmVz/aC1pbmdyZWRpZW50/c185NDQ0MjAtNDk1/ODcuanBnP3NpemU9/NjI2JmV4dD1qcGc",
        ingredients: [
            QuantifiedIngredient(name: "Romaine lettuce", quantity: 1, unit: .each),
            QuantifiedIngredient(name: "Croutons", quantity: 1, unit: .cup),
            QuantifiedIngredient(name: "Parmesan cheese", quantity: 0.5, unit: .cup),
            QuantifiedIngredient(name: "Caesar dressing", quantity: 0.25, unit: .cup),
            QuantifiedIngredient(name: "Chicken breast", quantity: 200, unit: .gram),
            QuantifiedIngredient(name: "Lemon juice", quantity: 1, unit: .tablespoon)
        ],
        instructions: [
            "Wash and chop lettuce",
            "Grill chicken and slice",
            "Toss lettuce with dressing",
            "Add chicken, croutons, and cheese",
            "Squeeze lemon juice over salad"
        ],
        prepTime: 10,
        cookTime: 0,
        calories: 200,
        cuisine: "American",
        servings: 4,
        description: "A refreshing salad with crisp romaine lettuce, grilled chicken, crunchy croutons, and a tangy Caesar dressing.",
        mealType: .lunch,
        createdBy: User(id: "1", name: "William Wallace", username: "william_wallace", email: "john.doe@example.com", profileImage: "https://imgs.search.brave.com/Aqyck6KGW7GjY4a_4nogz0H2B1kTCQi2QbnBzwYNyJs/rs:fit:500:0:0:0/g:ce/aHR0cHM6Ly90My5m/dGNkbi5uZXQvanBn/LzA4LzE1LzM4LzUw/LzM2MF9GXzgxNTM4/NTA4N18xeUFac3JC/aDFMTk1FaXVQMVdQ/NWlaS2pQdTdFbjFH/by5qcGc")
    ),
    Recipe(
        id: "4",
        name: "Chocolate Cake",
        image: "https://imgs.search.brave.com/T2lztXTHN5TotGT7FdvkMN0iEnxEC9Hr7ffofLW2wTo/rs:fit:500:0:0:0/g:ce/aHR0cHM6Ly9zdGF0/aWMwMS5ueXQuY29t/L2ltYWdlcy8yMDI0/LzA2LzIwL211bHRp/bWVkaWEveWEtZWFz/eS1jaG9jb2xhdGUt/bGF5ZXItY2FrZS1n/amNwL3lhLWVhc3kt/Y2hvY29sYXRlLWxh/eWVyLWNha2UtZ2pj/cC1sYXJnZUhvcml6/b250YWwzNzUuanBn/P3dpZHRoPTEyODAm/cXVhbGl0eT03NSZh/dXRvPXdlYnA",
        ingredients: [
            QuantifiedIngredient(name: "flour", quantity: 200, unit: .gram),
            QuantifiedIngredient(name: "sugar", quantity: 250, unit: .gram),
            QuantifiedIngredient(name: "cocoa powder", quantity: 75, unit: .gram),
            QuantifiedIngredient(name: "eggs", quantity: 2, unit: .each),
            QuantifiedIngredient(name: "vegetable oil", quantity: 120, unit: .milliliter),
            QuantifiedIngredient(name: "milk", quantity: 240, unit: .milliliter),
            QuantifiedIngredient(name: "baking powder", quantity: 2, unit: .teaspoon)
        ],
        instructions: [
            "Preheat oven to 180°C",
            "Mix dry ingredients",
            "Add wet ingredients and mix well",
            "Pour batter into cake pan",
            "Bake for 30-35 minutes",
            "Let cool before frosting"
        ],
        prepTime: 15,
        cookTime: 35,
        calories: 350,
        cuisine: "International",
        servings: 8,
        description: "A rich, moist chocolate cake that's perfect for any occasion. Easy to make and absolutely delicious.",
        mealType: .dessert,
        createdBy: User(id: "3", name: "Bob Dylan", username: "bob_dylan", email: "john.doe@example.com", profileImage: "https://imgs.search.brave.com/Aqyck6KGW7GjY4a_4nogz0H2B1kTCQi2QbnBzwYNyJs/rs:fit:500:0:0:0/g:ce/aHR0cHM6Ly90My5m/dGNkbi5uZXQvanBn/LzA4LzE1LzM4LzUw/LzM2MF9GXzgxNTM4/NTA4N18xeUFac3JC/aDFMTk1FaXVQMVdQ/NWlaS2pQdTdFbjFH/by5qcGc")
    ),
    Recipe(
        id: "5",
        name: "Sushi Roll",
        image: "https://imgs.search.brave.com/tIHpK7ol6eV-PdO1Q9qGHj9VPZ-an8KFSIrVNiH1PRk/rs:fit:860:0:0:0/g:ce/aHR0cHM6Ly9pbWcu/d29uZGVyaG93dG8u/Y29tL2ltZy81OS8w/NS82MzU3ODQ1MTAw/MTg2Mi8wL3JvbGwt/c3VzaGktdGhlLXVs/dGltYXRlLWd1aWRl/LncxNDU2LmpwZw",
        ingredients: [
            QuantifiedIngredient(name: "Sushi rice", quantity: 2, unit: .cup),
            QuantifiedIngredient(name: "Nori sheets", quantity: 4, unit: .each),
            QuantifiedIngredient(name: "Cucumber", quantity: 1, unit: .each),
            QuantifiedIngredient(name: "Avocado", quantity: 1, unit: .each),
            QuantifiedIngredient(name: "Imitation crab", quantity: 0.25, unit: .pound),
            QuantifiedIngredient(name: "Soy sauce", quantity: 2, unit: .tablespoon),
            QuantifiedIngredient(name: "Wasabi", quantity: 1, unit: .teaspoon)
        ],
        instructions: [
            "Prepare sushi rice",
            "Lay nori sheet on bamboo mat",
            "Spread rice on nori",
            "Add fillings",
            "Roll tightly",
            "Slice into pieces",
            "Serve with soy sauce and wasabi"
        ],
        prepTime: 20,
        cookTime: 10,
        calories: 250,
        cuisine: "Japanese",
        servings: 4,
        description: "Homemade sushi rolls filled with fresh vegetables and imitation crab. A fun and interactive meal to prepare and enjoy.",
        mealType: .appetizer,
        createdBy: User(id: "4", name: "Elvis Presley", username: "elvis_presley", email: "john.doe@example.com", profileImage: "https://imgs.search.brave.com/Aqyck6KGW7GjY4a_4nogz0H2B1kTCQi2QbnBzwYNyJs/rs:fit:500:0:0:0/g:ce/aHR0cHM6Ly90My5m/dGNkbi5uZXQvanBn/LzA4LzE1LzM4LzUw/LzM2MF9GXzgxNTM4/NTA4N18xeUFac3JC/aDFMTk1FaXVQMVdQ/NWlaS2pQdTdFbjFH/by5qcGc")
    ),
    Recipe(
        id: "6",
        name: "Vegetable Soup",
        image: "https://imgs.search.brave.com/0Y3xnYUOD1bPleg1J-adXEcWjO9zvVBeKob0kxE5IQY/rs:fit:500:0:0:0/g:ce/aHR0cHM6Ly9pb3dh/Z2lybGVhdHMuY29t/L3dwLWNvbnRlbnQv/dXBsb2Fkcy8yMDIw/LzExL0hhbWJ1cmdl/ci1Tb3VwLWlvd2Fn/aXJsZWF0cy1ORVct/RmVhdHVyZWQuanBn",
        ingredients: [
            QuantifiedIngredient(name: "Carrots", quantity: 2, unit: .each),
            QuantifiedIngredient(name: "Celery", quantity: 2, unit: .each),
            QuantifiedIngredient(name: "Onion", quantity: 1, unit: .each),
            QuantifiedIngredient(name: "Potatoes", quantity: 2, unit: .each),
            QuantifiedIngredient(name: "Vegetable broth", quantity: 1, unit: .liter),
            QuantifiedIngredient(name: "Tomatoes", quantity: 2, unit: .each),
            QuantifiedIngredient(name: "Mixed herbs", quantity: 1, unit: .tablespoon)
        ],
        instructions: [
            "Chop all vegetables",
            "Sauté onions in pot",
            "Add other vegetables and broth",
            "Bring to boil, then simmer",
            "Add herbs and season",
            "Cook until vegetables are tender"
        ],
        prepTime: 15,
        cookTime: 30,
        calories: 150,
        cuisine: "International",
        servings: 5,
        description: "A hearty and nutritious soup packed with a variety of vegetables. Perfect for a comforting meal on a cold day.",
        mealType: .entree,
        createdBy: User(id: "5", name: "Jimi Hendrix", username: "jimi_hendrix", email: "john.doe@example.com", profileImage: "https://imgs.search.brave.com/Aqyck6KGW7GjY4a_4nogz0H2B1kTCQi2QbnBzwYNyJs/rs:fit:500:0:0:0/g:ce/aHR0cHM6Ly90My5m/dGNkbi5uZXQvanBn/LzA4LzE1LzM4LzUw/LzM2MF9GXzgxNTM4/NTA4N18xeUFac3JC/aDFMTk1FaXVQMVdQ/NWlaS2pQdTdFbjFH/by5qcGc")
    )
]
