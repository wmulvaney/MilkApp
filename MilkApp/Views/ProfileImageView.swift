import SwiftUI

struct ProfileImageView: View {
    @ObservedObject var authService: AuthenticationService
    var user: User?
    var size: CGFloat = 30
    
    var body: some View {
        Group {
            if let imageUrlString = user?.profileImage ?? authService.currentUser?.profileImage {
                AsyncImage(url: URLHelper.cleanAndValidateURL(imageUrlString)) { phase in
                    switch phase {
                    case .empty:
                        fallbackImage
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size, height: size)
                            .clipShape(Circle())
                    case .failure(let error):
                        fallbackImage
                            .onAppear {
                                print("Failed to load image: \(error.localizedDescription)")
                                print("URL attempted: \(imageUrlString)")
                            }
                    @unknown default:
                        fallbackImage
                    }
                }
            } else {
                fallbackImage
                    .onAppear {
                        print("No profile image URL available")
                    }
            }
        }
    }
    
    private var fallbackImage: some View {
        Image(systemName: "person.circle")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
    }
}
