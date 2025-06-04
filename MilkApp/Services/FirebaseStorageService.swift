import Foundation
import FirebaseStorage
import UIKit

class FirebaseStorageService {
    static let shared = FirebaseStorageService()
    private init() {}
    
    func uploadImage(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            let error = NSError(domain: "FirebaseStorageService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
            completion(.failure(error))
            return
        }
        
        let storageRef = Storage.storage().reference()
        let imageRef = storageRef.child("\(UUID().uuidString).jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        imageRef.putData(imageData, metadata: metadata) { (metadata, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            imageRef.downloadURL { (url, error) in
                if let error = error {
                    completion(.failure(error))
                } else if let url = url {
                    completion(.success(url.absoluteString))
                } else {
                    let error = NSError(domain: "FirebaseStorageService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"])
                    completion(.failure(error))
                }
            }
        }
    }
}
