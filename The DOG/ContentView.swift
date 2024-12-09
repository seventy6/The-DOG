//
//  ContentView.swift
//  The DOG
//
//  Created by Nick W Forsberg on 08/12/2024.
//

import SwiftUI

struct Weight: Codable {
    let imperial: String
    let metric: String
}

struct Breed: Codable {
    let weight: Weight
    let name: String
    let temperament: String?
    let origin: String?
    let description: String?
    let lifeSpan: String?
    
    // Characteristics (1-5 scale)
    let adaptability: Int?
    let affectionLevel: Int?
    let childFriendly: Int?
    let dogFriendly: Int?
    let energyLevel: Int?
    let intelligence: Int?
    
    enum CodingKeys: String, CodingKey {
        case weight, name, temperament, origin, description
        case lifeSpan = "life_span"
        case adaptability, intelligence
        case affectionLevel = "affection_level"
        case childFriendly = "child_friendly"
        case dogFriendly = "dog_friendly"
        case energyLevel = "energy_level"
    }
}

struct DogImage: Codable, Identifiable {
    let id: String
    let url: String
    let width: Int
    let height: Int
    var favoriteId: Int?
    let breeds: [Breed]?
}

struct CharacteristicRow: View {
    let title: String
    let rating: Int
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { index in
                    Image(systemName: index <= rating ? "circle.fill" : "circle")
                        .foregroundStyle(index <= rating ? .blue : .gray)
                        .font(.caption)
                }
            }
        }
    }
}

struct HeartBurst: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            ForEach(0..<8) { index in
                Image(systemName: "heart.fill")
                    .foregroundStyle(.red)
                    .scaleEffect(isAnimating ? 0.1 : 1.0)
                    .opacity(isAnimating ? 0 : 1)
                    .offset(
                        x: isAnimating ? 0 : 20 * cos(Double(index) * .pi / 4),
                        y: isAnimating ? 0 : 20 * sin(Double(index) * .pi / 4)
                    )
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                isAnimating = true
            }
        }
    }
}

struct ContentView: View {
    @State private var currentDog: DogImage?
    @State private var isLoading = false
    @State private var favoriteImages: [DogImage] = []
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var animatingImage: DogImage?
    @State private var startPosition: CGPoint = .zero
    @State private var heartIconPosition: CGPoint = .zero
    @Namespace private var animation
    @State private var showHeartBurst = false
    @State private var animationScale: CGFloat = 1.0
    @State private var imageFrame: CGRect = .zero
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isLoading {
                    ProgressView()
                        .controlSize(.large)
                } else if let dog = currentDog {
                    ScrollView {
                        VStack(spacing: 16) {
                            AsyncImage(url: URL(string: dog.url)) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .cornerRadius(10)
                                        .background(
                                            GeometryReader { geometry in
                                                Color.clear
                                                    .preference(
                                                        key: ViewFrameKey.self,
                                                        value: geometry.frame(in: .global)
                                                    )
                                            }
                                        )
                                case .failure:
                                    Image(systemName: "photo")
                                        .imageScale(.large)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .padding(.horizontal)
                            
                            if let breed = dog.breeds?.first {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text(breed.name)
                                        .font(.title2)
                                        .bold()
                                    
                                    if let origin = breed.origin {
                                        Label(origin, systemImage: "globe")
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    if let description = breed.description {
                                        Text(description)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    if let temperament = breed.temperament {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Temperament")
                                                .font(.headline)
                                            Text(temperament)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Characteristics")
                                            .font(.headline)
                                        
                                        if let intelligence = breed.intelligence {
                                            CharacteristicRow(title: "Intelligence", rating: intelligence)
                                        }
                                        if let affection = breed.affectionLevel {
                                            CharacteristicRow(title: "Affection", rating: affection)
                                        }
                                        if let energy = breed.energyLevel {
                                            CharacteristicRow(title: "Energy", rating: energy)
                                        }
                                        if let dogFriendly = breed.dogFriendly {
                                            CharacteristicRow(title: "Dog Friendly", rating: dogFriendly)
                                        }
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(.background)
                                        .shadow(radius: 2)
                                )
                                .padding(.horizontal)
                            }
                            
                            HStack(spacing: 40) {
                                Button(action: { handleVote(like: false) }) {
                                    Image(systemName: "hand.thumbsdown.fill")
                                        .imageScale(.large)
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.bordered)
                                
                                Button(action: { handleVote(like: true) }) {
                                    Image(systemName: "hand.thumbsup.fill")
                                        .imageScale(.large)
                                        .foregroundStyle(.green)
                                }
                                .buttonStyle(.bordered)
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Random Dogs")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: FavoritesView(favoriteImages: favoriteImages, onRefresh: loadFavorites)) {
                        Image(systemName: "heart.fill")
                            .background(
                                GeometryReader { geometry in
                                    Color.clear
                                        .onAppear {
                                            heartIconPosition = CGPoint(
                                                x: geometry.frame(in: .global).midX,
                                                y: geometry.frame(in: .global).midY
                                            )
                                        }
                                }
                            )
                    }
                }
            }
            .overlay {
                if let animatingDog = animatingImage {
                    AsyncImage(url: URL(string: animatingDog.url)) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .position(startPosition)
                                .scaleEffect(animationScale)
                        }
                    }
                }
                
                if showHeartBurst {
                    HeartBurst()
                        .position(heartIconPosition)
                }
            }
        }
        .onPreferenceChange(ViewFrameKey.self) { frame in
            imageFrame = frame
        }
        .task {
            await fetchRandomDog()
            await loadFavorites()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    func fetchRandomDog() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            currentDog = try await DogAPIService.shared.fetchRandomDog()
        } catch {
            print("Error fetching dog: \(error)")
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func loadFavorites() async {
        do {
            favoriteImages = try await DogAPIService.shared.getFavorites()
        } catch {
            errorMessage = "Failed to load favorites: \(error.localizedDescription)"
            showError = true
        }
    }
    
    func handleVote(like: Bool) {
        if like, let dog = currentDog {
            startPosition = CGPoint(x: imageFrame.midX, y: imageFrame.midY)
            animatingImage = dog
            animationScale = 1.0
            
            withAnimation(.spring(duration: 0.6, bounce: 0.3)) {
                startPosition = heartIconPosition
                animationScale = 0.5
            }
            
            // Add haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            // Delay to match animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                animatingImage = nil
                showHeartBurst = true
                
                // Hide heart burst after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        showHeartBurst = false
                    }
                }
                
                // Save the favorite
                Task {
                    do {
                        try await DogAPIService.shared.addToFavorites(imageId: dog.id)
                        await loadFavorites()
                    } catch {
                        errorMessage = "Failed to add to favorites: \(error.localizedDescription)"
                        showError = true
                    }
                }
            }
        }
        Task {
            await fetchRandomDog()
        }
    }
}

struct FavoritesView: View {
    let favoriteImages: [DogImage]
    let onRefresh: () async -> Void
    
    @State private var isDeleting = Set<String>()
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading favorites...")
                    .controlSize(.large)
            } else if favoriteImages.isEmpty {
                ContentUnavailableView(
                    "No Favorites Yet",
                    systemImage: "heart.slash",
                    description: Text("Your favorite dogs will appear here")
                )
            } else {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(favoriteImages) { dog in
                            DogImageCell(
                                dog: dog,
                                isDeleting: isDeleting.contains(dog.id),
                                onDelete: { await deleteFavorite(dog) }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Favorites")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .task {
            isLoading = true
            await onRefresh()
            isLoading = false
        }
    }
    
    func deleteFavorite(_ dog: DogImage) async {
        guard let favoriteId = dog.favoriteId else { return }
        
        isDeleting.insert(dog.id)
        defer { isDeleting.remove(dog.id) }
        
        do {
            try await DogAPIService.shared.deleteFavorite(favoriteId: favoriteId)
            await onRefresh()
        } catch {
            errorMessage = "Failed to delete favorite: \(error.localizedDescription)"
            showError = true
        }
    }
}

struct DogImageCell: View {
    let dog: DogImage
    let isDeleting: Bool
    let onDelete: () async -> Void
    
    var body: some View {
        AsyncImage(url: URL(string: dog.url)) { phase in
            ZStack {
                switch phase {
                case .empty:
                    ProgressView()
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    Image(systemName: "photo")
                        .imageScale(.large)
                @unknown default:
                    EmptyView()
                }
                
                if isDeleting {
                    Color.black.opacity(0.3)
                    ProgressView()
                        .tint(.white)
                }
            }
        }
        .frame(height: 150)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            Button(action: {
                Task {
                    await onDelete()
                }
            }) {
                Image(systemName: "trash.circle.fill")
                    .font(.title)
                    .foregroundStyle(.red)
                    .background(
                        Circle()
                            .fill(.white)
                            .padding(4)
                    )
            }
            .disabled(isDeleting)
            .opacity(isDeleting ? 0 : 1)
            .padding(8),
            alignment: .topTrailing
        )
    }
}

#Preview {
    ContentView()
}

// Add this extension to support the completion handler
extension Animation {
    func completion(_ completion: @escaping () -> Void) -> Animation {
        let duration = Mirror(reflecting: self).children.first { $0.label == "duration" }?.value as? Double ?? 0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            completion()
        }
        
        return self
    }
}

// Add this preference key
struct ViewFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}
