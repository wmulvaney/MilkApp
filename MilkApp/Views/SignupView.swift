import SwiftUI

struct SignupView: View {
    @State private var email = ""
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    @Environment(\.presentationMode) var presentationMode
    
    var isLoggedIn: Bool {
        return AuthenticationService.shared.isLoggedIn
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Account Information")) {
                    TextField("Email", text: $email)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    TextField("Username", text: $username)
                        .autocapitalization(.none)
                        .autocorrectionDisabled(true)
                }
                
                Section(header: Text("Password")) {
                    SecureField("Password", text: $password)
                    SecureField("Confirm Password", text: $confirmPassword)
                }
                
                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
                
                Section {
                    Button("Sign Up") {
                        signup()
                    }
                }
            }
            .navigationTitle("Sign Up")
        }
    }
    
    private func signup() {
        guard !email.isEmpty, !username.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }
        
        AuthenticationService.shared.signup(email: email, username: username, password: password) { success, message in
            DispatchQueue.main.async {
                if success {
                    presentationMode.wrappedValue.dismiss()
                } else {
                    errorMessage = message ?? "An error occurred during signup"
                    print("Signup failed. Error: \(errorMessage)")
                }
            }
        }
    }
}
