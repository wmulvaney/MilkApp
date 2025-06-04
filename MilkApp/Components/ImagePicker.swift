import SwiftUI
import PhotosUI

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    var sourceType: UIImagePickerController.SourceType
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        print("Creating PHPickerViewController")
        var config = PHPickerConfiguration()
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            print("Did finish picking")
            parent.presentationMode.wrappedValue.dismiss()
            
            guard let provider = results.first?.itemProvider else {
                print("No image provider")
                return
            }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, error in
                    if let error = error {
                        print("Error loading image: \(error)")
                        return
                    }
                    
                    DispatchQueue.main.async {
                        print("Setting image")
                        self.parent.image = image as? UIImage
                    }
                }
            }
        }
    }
}
