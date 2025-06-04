import SwiftUI
import UIKit

struct UserSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var authService = AuthenticationService.shared
    @State private var showImagePicker = false
    @State private var inputImage: UIImage?
    @State private var profileImage: Image?
    @State private var isUploading = false
    @State private var uploadError: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    profileImageView
                        .padding(.vertical)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    if isUploading {
                        ProgressView("Uploading...")
                    }
                    
                    if let error = uploadError {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
                
                Section(header: Text("User Information")) {
                    HStack {
                        Text("Username")
                        Spacer()
                        Text(authService.currentUser?.username ?? "")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Email")
                        Spacer()
                        Text(authService.currentUser?.email ?? "")
                            .foregroundColor(.secondary)
                    }
                }

                Section {
                    Button("Logout") {
                        logout()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("User Settings")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
        .sheet(isPresented: $showImagePicker, onDismiss: loadImage) {
            ImagePicker(image: $inputImage, sourceType: .camera)
        }
        .onAppear(perform: loadProfileImage)
    }
    
    private var profileImageView: some View {
        ZStack(alignment: .bottomTrailing) {
            if let profileImage = profileImage {
                profileImage
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 4))
                    .shadow(radius: 7)
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundColor(.gray)
            }
            
            Image(systemName: "pencil.circle.fill")
                .resizable()
                .frame(width: 30, height: 30)
                .foregroundColor(.blue)
                .onTapGesture {
                    showImagePicker = true
                }
        }
    }

    private func loadProfileImage() {
        guard let imageUrlString = authService.currentUser?.profileImage else {
            print("No image URL found")
            return
        }
        
        print("Original image URL: \(imageUrlString)")
        
        guard let url = URLHelper.cleanAndValidateURL(imageUrlString) else {
            print("Failed to create valid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error loading image: \(error.localizedDescription)")
                print("Error domain: \(error.localizedDescription), code: \((error as NSError).code)")
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status code: \(httpResponse.statusCode)")
            }
            if let data = data, let uiImage = UIImage(data: data) {
                print("Image data received and converted to UIImage")
                DispatchQueue.main.async {
                    profileImage = Image(uiImage: uiImage)
                    print("Profile image set")
                }
            } else {
                print("Failed to create UIImage from data")
            }
        }.resume()
    }
    
    private func loadImage() {
        guard let inputImage = inputImage else { return }
        profileImage = Image(uiImage: inputImage)
        
        print("Current auth token before update: \(authService.authToken ?? "No token")")
        
        isUploading = true
        uploadError = nil
        
        FirebaseStorageService.shared.uploadImage(inputImage) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let imageUrl):
                    print("Image uploaded successfully to Firebase. URL: \(imageUrl)")
                    updateUserProfileOnServer(imageUrl: imageUrl)
                case .failure(let error):
                    isUploading = false
                    print("Failed to upload image to Firebase: \(error.localizedDescription)")
                    uploadError = "Failed to upload image: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func updateUserProfileOnServer(imageUrl: String) {
        guard let token = authService.authToken else {
            uploadError = "No authentication token available"
            isUploading = false
            return
        }

        let url = URL(string: "\(authService.baseURL)/set-profile-image/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Token \(token)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = ["image_url": imageUrl]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            uploadError = "Failed to prepare request: \(error.localizedDescription)"
            isUploading = false
            return
        }

        print("Sending request with token: Token \(token)")
        print("Request URL: \(url)")
        print("Request headers: \(request.allHTTPHeaderFields ?? [:])")
        print("Request body: \(String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "")")

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async { [self] in
                self.isUploading = false
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("HTTP Response Status code: \(httpResponse.statusCode)")
                }
                
                if let error = error {
                    print("Network Error: \(error.localizedDescription)")
                    self.uploadError = "Server request failed: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    print("No data received from server")
                    self.uploadError = "No data received from server"
                    return
                }
                
                print("Raw server response: \(String(data: data, encoding: .utf8) ?? "Unable to convert data to string")")
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        print("Parsed JSON response: \(json)")
                        if let success = json["success"] as? Bool {
                            if success {
                                print("Profile image updated successfully on server")
                                self.authService.updateProfileImage(url: imageUrl)
                            } else {
                                let message = json["message"] as? String ?? "Unknown error occurred"
                                print("Server reported failure: \(message)")
                                self.uploadError = message
                            }
                        } else {
                            print("JSON does not contain 'success' key")
                            self.uploadError = "Invalid response from server"
                        }
                    } else {
                        print("Failed to parse JSON from response")
                        self.uploadError = "Invalid response from server"
                    }
                } catch {
                    print("JSON Parsing Error: \(error.localizedDescription)")
                    self.uploadError = "Failed to parse server response: \(error.localizedDescription)"
                }
            }
        }.resume()
    }

    private func logout() {
        AuthenticationService.shared.logout()
        presentationMode.wrappedValue.dismiss()
    }
}

struct UserSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        UserSettingsView()
    }
}
