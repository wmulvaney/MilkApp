//
//  LoginView.swift
//  MilkApp
//
//  Created by William Mulvaney on 10/1/24.
//

import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var showingSignup = false
    @State private var isLoggedIn = false
    @State private var isLoading = false
    @State private var userId = ""
    @State private var token = ""

    var body: some View {
        NavigationView {
            VStack {
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .padding()
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button("Login") {
                    login()
                }
                .padding()
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                Button("Don't have an account? Sign up") {
                    showingSignup = true
                }
                .padding()
            }
            .padding()
            .navigationTitle("Login")
        }
        .sheet(isPresented: $showingSignup) {
            SignupView()
        }
    }
    
    private func login() {
        isLoading = true
        AuthenticationService.shared.login(email: email, password: password) { success, response in
            DispatchQueue.main.async {
                self.isLoading = false
                if success, let user = response?.user, let token = response?.token {
                    AuthenticationService.shared.setLoggedIn(user: user, token: token)
                    self.isLoggedIn = true
                    self.userId = user.id ?? ""
                    self.token = token
                } else {
                    self.errorMessage = response?.message ?? "Login failed"
                }
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
