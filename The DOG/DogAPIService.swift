import Foundation

enum DogAPIError: Error {
    case invalidURL
    case serverError(String)
    case decodingError
}

struct FavoriteResponse: Codable {
    let id: Int
    let imageId: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case imageId = "image_id"
    }
}

class DogAPIService {
    static let shared = DogAPIService()
    private let baseURL = "https://api.thedogapi.com/v1"
    private let apiKey = "live_O31vdDmEDs1a5px4SVzNiCIhn0wZWAb7KvA6mK0IZDKrsiHfUF4bxqSDIDaKCV5R"
    
    private init() {}
    
    private func createRequest(url: URL, method: String = "GET") -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }
    
    func fetchRandomDog() async throws -> DogImage {
        guard let url = URL(string: "\(baseURL)/images/search") else {
            throw DogAPIError.invalidURL
        }
        
        let request = createRequest(url: url)
        let (data, _) = try await URLSession.shared.data(for: request)
        let dogs = try JSONDecoder().decode([DogImage].self, from: data)
        
        guard let dog = dogs.first else {
            throw DogAPIError.serverError("No dog image returned")
        }
        
        return dog
    }
    
    func addToFavorites(imageId: String) async throws {
        guard let url = URL(string: "\(baseURL)/favourites") else {
            throw DogAPIError.invalidURL
        }
        
        var request = createRequest(url: url, method: "POST")
        let body = ["image_id": imageId]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...201).contains(httpResponse.statusCode) else {
            throw DogAPIError.serverError("Failed to add to favorites")
        }
    }
    
    func getFavorites() async throws -> [DogImage] {
        guard let url = URL(string: "\(baseURL)/favourites") else {
            throw DogAPIError.invalidURL
        }
        
        let request = createRequest(url: url)
        let (data, _) = try await URLSession.shared.data(for: request)
        let favorites = try JSONDecoder().decode([FavoriteResponse].self, from: data)
        
        // Fetch details for each favorite image
        var dogImages: [DogImage] = []
        for favorite in favorites {
            guard let imageUrl = URL(string: "\(baseURL)/images/\(favorite.imageId)") else { continue }
            let imageRequest = createRequest(url: imageUrl)
            let (imageData, _) = try await URLSession.shared.data(for: imageRequest)
            if var dogImage = try? JSONDecoder().decode(DogImage.self, from: imageData) {
                dogImage.favoriteId = favorite.id  // Set the favorite ID
                dogImages.append(dogImage)
            }
        }
        
        return dogImages
    }
    
    func deleteFavorite(favoriteId: Int) async throws {
        guard let url = URL(string: "\(baseURL)/favourites/\(favoriteId)") else {
            throw DogAPIError.invalidURL
        }
        
        let request = createRequest(url: url, method: "DELETE")
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw DogAPIError.serverError("Failed to delete favorite")
        }
    }
} 