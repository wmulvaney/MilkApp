import Foundation

class AspectRatioCache {
    static let shared = AspectRatioCache()
    
    private var cache: [String: CGFloat] = [:]
    
    private init() {}
    
    func getAspectRatio(for recipeId: String) -> CGFloat {
        if let cachedRatio = cache[recipeId] {
            return cachedRatio
        }
        
        let newRatio = CGFloat.random(in: 1...2)
        cache[recipeId] = newRatio
        return newRatio
    }
}
