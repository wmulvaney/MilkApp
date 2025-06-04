//
//  ContentView.swift
//  MilkApp
//
//  Created by William Mulvaney on 9/25/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authObserver = AuthenticationObserver()
    @StateObject private var recipeManager = RecipeManager()
    @State private var showingCreateView = false
    @State private var selectedTab = 0

    var user = AuthenticationService.shared.currentUser;

    var body: some View {
        if authObserver.isLoggedIn {
            ZStack(alignment: .bottom) {
                TabView(selection: $selectedTab) {
                    HomeView(recipeManager: recipeManager)
                        .tabItem {
                            Image(systemName: "house")
                            Text("Home")
                        }
                        .tag(0)
                
                    CookView(recipeManager: recipeManager)
                        .tabItem {
                            Image(systemName: "fork.knife")
                            Text("Cook")
                        }
                        .tag(1)
                
                    Color.clear
                        .tabItem { Text("") }
                        .tag(2)
                
                    ShopView(recipeManager: recipeManager)
                        .tabItem {
                            Image(systemName: "cart")
                            Text("Shop")
                        }
                        .tag(3)
                
                    UserProfileView(user: user ?? User(id: "", name: nil, username: "", email: "", profileImage: nil))
                        .tabItem {
                            Image(systemName: "person")
                            Text("Profile")
                        }
                        .tag(4)
                }
                
                VStack {
                    Spacer()
                    Button(action: {
                        showingCreateView = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 60, height: 60)
                            .foregroundColor(.blue)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                }
                if showingCreateView {
                    ZStack {
                        Color.black.opacity(0.5)
                            .edgesIgnoringSafeArea(.all)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                showingCreateView = false
                            }
                        
                        CreateView(recipeManager: recipeManager, userId: authObserver.userId, isPresented: $showingCreateView)
                            .transition(.move(edge: .bottom))
                    }
                }
            }
        } else {
            LoginView()
        }
    }
}

class AuthenticationObserver: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var userId: String = ""
    
    init() {
        updateState()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateState),
            name: Notification.Name(AuthenticationService.authStateDidChangeNotification),
            object: nil
        )
    }
    
    @objc func updateState() {
        isLoggedIn = AuthenticationService.shared.isLoggedIn
        userId = AuthenticationService.shared.currentUser?.id ?? ""
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
