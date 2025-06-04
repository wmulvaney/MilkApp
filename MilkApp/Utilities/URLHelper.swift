import Foundation

struct URLHelper {
    static func cleanAndValidateURL(_ urlString: String) -> URL? {
        var cleanedString = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove leading slash if present
        if cleanedString.hasPrefix("/") {
            cleanedString.removeFirst()
        }
        
        // Decode the URL if it's percent-encoded
        if let decodedString = cleanedString.removingPercentEncoding {
            cleanedString = decodedString
        }
        
        
        return URL(string: cleanedString)
    }
}

extension String {
    func contains(_ other: String, after index: String.Index) -> Bool {
        return self[index...].contains(other)
    }
}
