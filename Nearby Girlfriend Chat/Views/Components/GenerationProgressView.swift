//
//  GenerationProgressView.swift
//  Nearby Girlfriend Chat
//

import SwiftUI

struct GenerationProgressView: View {
    let progress: Double
    let generatedCount: Int
    let totalCount: Int
    let status: GenerationStatus
    let locationText: String
    
    @State private var animatedProgress: Double = 0
    @State private var pulseAnimation = false
    @State private var heartBeat = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Animated heart icon
            ZStack {
                // Pulse rings
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.pink, .purple.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 100 + CGFloat(index * 30), height: 100 + CGFloat(index * 30))
                        .opacity(pulseAnimation ? 0 : 0.5 - Double(index) * 0.15)
                        .scaleEffect(pulseAnimation ? 1.3 : 1)
                        .animation(
                            .easeOut(duration: 1.5)
                                .repeatForever(autoreverses: false)
                                .delay(Double(index) * 0.3),
                            value: pulseAnimation
                        )
                }
                
                // Heart icon
                Image(systemName: "heart.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.pink, .red],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .scaleEffect(heartBeat ? 1.1 : 1)
                    .animation(
                        .easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true),
                        value: heartBeat
                    )
            }
            .frame(height: 180)
            
            // Status text
            VStack(spacing: 8) {
                Text(status.displayText)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.pink)
                    
                    Text(locationText)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress bar
            VStack(spacing: 10) {
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 12)
                    
                    // Progress fill
                    GeometryReader { geometry in
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [.pink, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(0, geometry.size.width * animatedProgress))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            colors: [.white.opacity(0.3), .clear],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            )
                    }
                    .frame(height: 12)
                }
                .frame(maxWidth: 280)
                
                // Count text
                HStack {
                    Text("\(generatedCount)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.pink)
                    
                    Text("of \(totalCount) matches found")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
            
            // Tip text
            Text("This usually takes about a minute")
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundColor(.secondary.opacity(0.7))
                .padding(.top, 8)
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
        .onAppear {
            pulseAnimation = true
            heartBeat = true
            withAnimation(.easeOut(duration: 0.8)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { newValue in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedProgress = newValue
            }
        }
    }
}

// Mini progress indicator for header
struct MiniProgressIndicator: View {
    let progress: Double
    let count: Int
    let total: Int
    
    var body: some View {
        HStack(spacing: 8) {
            // Mini progress ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [.pink, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 24, height: 24)
            
            Text("\(count)/\(total)")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color(.systemGray6))
        )
    }
}

#Preview {
    VStack {
        GenerationProgressView(
            progress: 0.6,
            generatedCount: 9,
            totalCount: 30,
            status: .inProgress,
            locationText: "San Francisco, CA"
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

