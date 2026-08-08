//
//  CachedAsyncImage.swift
//  Nearby Girlfriend Chat
//
//  A robust async image loader that:
//  - Shows a shimmer loading skeleton while loading
//  - Retries automatically on failure (up to 3 times)
//  - Clears the URL cache entry on failure to force a fresh load on retry
//  - Shows a beautiful placeholder if all retries fail
//

import SwiftUI

// MARK: - Shimmer Effect

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .white.opacity(0.35), location: 0.4),
                            .init(color: .white.opacity(0.5), location: 0.5),
                            .init(color: .white.opacity(0.35), location: 0.6),
                            .init(color: .clear, location: 1),
                        ],
                        startPoint: .init(x: phase - 0.3, y: 0),
                        endPoint: .init(x: phase + 0.3, y: 0)
                    )
                    .frame(width: geo.size.width, height: geo.size.height)
                }
            )
            .onAppear {
                withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                    phase = 1.3
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
}

// MARK: - CachedAsyncImage

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let maxRetries: Int
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    
    @State private var phase: AsyncImagePhase = .empty
    @State private var loadId = UUID()
    
    init(
        url: URL?,
        maxRetries: Int = 3,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.maxRetries = maxRetries
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            switch phase {
            case .success(let image):
                content(image)
            case .failure:
                placeholder()
            case .empty:
                shimmerPlaceholder
            @unknown default:
                shimmerPlaceholder
            }
        }
        .id(loadId)
        .task(id: loadId) {
            await loadImage()
        }
    }
    
    private var shimmerPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [Color(.systemGray5), Color(.systemGray4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .shimmer()
            
            Image(systemName: "person.fill")
                .font(.system(size: 40))
                .foregroundColor(Color(.systemGray3))
        }
        .aspectRatio(0.8, contentMode: .fill)
    }
    
    @MainActor
    private func loadImage() async {
        guard let url = url else {
            phase = .failure(URLError(.badURL))
            return
        }
        
        phase = .empty
        
        for attempt in 0...maxRetries {
            do {
                // Bypass URLCache on retries to force fresh load from server
                var request = URLRequest(url: url)
                request.cachePolicy = attempt == 0 ? .returnCacheDataElseLoad : .reloadIgnoringLocalCacheData
                request.timeoutInterval = 20
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                
                guard let uiImage = UIImage(data: data) else {
                    throw URLError(.cannotDecodeContentData)
                }
                
                phase = .success(Image(uiImage: uiImage))
                return
                
            } catch {
                // Evict the failed/stale cache entry before next retry
                URLCache.shared.removeCachedResponse(for: URLRequest(url: url))
                
                if attempt < maxRetries {
                    // Exponential-ish backoff: 1s, 2s, 3s
                    let delay = UInt64(1_000_000_000 * (attempt + 1))
                    try? await Task.sleep(nanoseconds: delay)
                } else {
                    phase = .failure(error)
                }
            }
        }
    }
}

// MARK: - Default placeholder convenience

extension CachedAsyncImage where Placeholder == AnyView {
    init(
        url: URL?,
        maxRetries: Int = 3,
        @ViewBuilder content: @escaping (Image) -> Content
    ) {
        self.init(
            url: url,
            maxRetries: maxRetries,
            content: content,
            placeholder: {
                AnyView(
                    ZStack {
                        LinearGradient(
                            colors: [.pink.opacity(0.2), .purple.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        Image(systemName: "person.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white.opacity(0.5))
                    }
                )
            }
        )
    }
}
