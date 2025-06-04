import SwiftUI
import PhotosUI

struct ImageUploadButton: View {
    @Binding var image: UIImage?
    @Binding var imageUrl: String?
    @State private var showingImagePicker = false
    @State private var isUploading = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    var onUploadComplete: (() -> Void)? // Add this
    
    var body: some View {
        Button(action: {
            showingImagePicker = true
        }) {
            if isUploading || isLoading {
                ProgressView()
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                VStack {
                    Image(systemName: "plus")
                        .font(.system(size: 40))
                    Text("Add Image")
                        .font(.caption)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .disabled(isUploading || isLoading)
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $image, sourceType: .camera)
        }
        .onChange(of: image) { newImage in
            if let newImage = newImage {
                uploadImage(newImage)
            }
        }
        .onChange(of: imageUrl) { newImageUrl in
            if let urlString = newImageUrl, image == nil {
                loadImage(from: urlString)
            }
        }
        .onAppear {
            if let urlString = imageUrl, image == nil {
                loadImage(from: urlString)
            }
        }
        .alert(item: Binding<AlertItem?>(
            get: { errorMessage.map { AlertItem(message: $0) } },
            set: { _ in errorMessage = nil }
        )) { alertItem in
            Alert(title: Text("Image Error"), message: Text(alertItem.message))
        }
    }
    
    private func uploadImage(_ image: UIImage) {
        isUploading = true
        FirebaseStorageService.shared.uploadImage(image) { result in
            DispatchQueue.main.async {
                self.isUploading = false
                switch result {
                case .success(let url):
                    self.imageUrl = url
                    self.onUploadComplete?() // Add this
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func loadImage(from urlString: String) {
        guard let url = URLHelper.cleanAndValidateURL(urlString) else {
            return
        }
        
        isLoading = true
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = "Failed to load image"
                } else if let data = data, let uiImage = UIImage(data: data) {
                    self.image = uiImage
                } else {
                    self.errorMessage = "Failed to load image"
                }
            }
        }.resume()
    }
}

struct AlertItem: Identifiable {
    let id = UUID()
    let message: String
}
