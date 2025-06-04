import SwiftUI

struct UserProfileView: View {
    let user: User
    @State private var isFollowing = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isCurrentUser: Bool = false
    @State private var recipeBooks: [RecipeBook] = []
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            VStack {
                AsyncImage(url: URLHelper.cleanAndValidateURL(user.profileImage ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(.gray)
                }
                .frame(width: 120, height: 120)
                .clipShape(Circle())
                .padding(.top)
                
                Text(user.name ?? "")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("@\(user.username)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if !isCurrentUser {
                    Button(action: {
                        if isFollowing {
                            unfollowUser()
                        } else {
                            followUser()
                        }
                    }) {
                        Text(isFollowing ? "Unfollow" : "Follow")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(isFollowing ? Color.gray : Color.blue)
                            .cornerRadius(20)
                    }
                    .padding()
                }
                
                Text("Recipe Books")
                    .font(.title2)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(recipeBooks, id: \.id) { recipeBook in
                        VStack {
                            AsyncImage(url: URLHelper.cleanAndValidateURL(recipeBook.coverImage ?? "")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Image(systemName: "book.circle.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .foregroundColor(.gray)
                            }
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            
                            Text(recipeBook.title)
                                .font(.headline)
                                .lineLimit(1)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Follow Status"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .onAppear {
            checkIfCurrentUser()
            checkFollowStatus()
            fetchUserRecipeBooks()
        }
    }
    
    private func fetchUserRecipeBooks() {
        UserService.shared.getUserRecipeBooks(userId: user.id) { success, recipeBooks, errorMessage in
            DispatchQueue.main.async {
                if success, let recipeBooks = recipeBooks {
                    self.recipeBooks = recipeBooks
                } else {
                    self.alertMessage = errorMessage ?? "Failed to fetch recipe books"
                    self.showingAlert = true
                }
            }
        }
    }
    
    private func checkIfCurrentUser() {
        if let currentUserId = AuthenticationService.shared.currentUser?.id {
            isCurrentUser = (currentUserId == user.id)
        }
    }
    
    private func checkFollowStatus() {
        UserService.shared.isFollowing(userId: user.id) { success, isFollowing, errorMessage in
            DispatchQueue.main.async {
                if success, let isFollowing = isFollowing {
                    self.isFollowing = isFollowing
                } else {
                    self.alertMessage = errorMessage ?? "Failed to check follow status"
                    self.showingAlert = true
                }
            }
        }
    }
    
    private func followUser() {
        UserService.shared.followUser(userId: user.id) { success, message in
            DispatchQueue.main.async {
                if success {
                    isFollowing.toggle()
                }
                alertMessage = message ?? "An error occurred"
                showingAlert = true
            }
        }
    }
    
    private func unfollowUser() {
        UserService.shared.unfollowUser(userId: user.id) { success, message in
            DispatchQueue.main.async {
                if success {
                    isFollowing.toggle()
                }
                alertMessage = message ?? "An error occurred"
                showingAlert = true
            }
        }
    }
}

struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        UserProfileView(
            user: User(id: "1", name: "John Doe", username: "johndoe", email: "jdoe@john.com", profileImage: nil)
        )
    }
}
