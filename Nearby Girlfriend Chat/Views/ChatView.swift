//
//  ChatView.swift
//  Nearby Girlfriend Chat
//

import SwiftUI
import UIKit

// Helper extension for adaptive colors
extension Color {
    static var aiMessageText: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor.white : UIColor.black
        })
    }
    
    static var aiMessageBackground: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor.systemGray5 : UIColor.systemGray6
        })
    }
}

struct ChatMessage: Identifiable, Equatable, Codable {
    let id: UUID
    let text: String
    let isUser: Bool
    let timestamp: Date
    var isLoading: Bool = false
    var isError: Bool = false
    var imageURL: String? = nil
    
    init(text: String, isUser: Bool, timestamp: Date = Date(), isLoading: Bool = false, isError: Bool = false, imageURL: String? = nil) {
        self.id = UUID()
        self.text = text
        self.isUser = isUser
        self.timestamp = timestamp
        self.isLoading = isLoading
        self.isError = isError
        self.imageURL = imageURL
    }
}

struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: String
}

@MainActor
struct ChatView: View {
    let girlfriend: Girlfriend
    var source: ActiveConversation.ConversationSource = .nearby
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var chatsVM = ChatsViewModel.shared
    
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isTextLoading = false
    @State private var isImageLoading = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var conversationId: String = ""
    @AppStorage("isSelfieModeEnabled") private var isImageGenerationEnabled = false
    @State private var selectedImageURL: String? = nil
    @State private var showBanner = false
    @State private var bannerText = ""
    @State private var dotCount = 1
    @State private var isSkeletonPulsing = false
    @FocusState private var isInputFocused: Bool
    
    private let deviceId = DeviceService.shared.deviceId
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            // Welcome message
                            if messages.isEmpty {
                                welcomeMessage
                                    .padding(.top, 20)
                            }
                            
                            ForEach(messages) { message in
                                ChatBubble(
                                    message: message,
                                    avatarURL: girlfriend.avatarUrls.primaryURL,
                                    onRetry: message.isError ? { retryLastMessage() } : nil,
                                    onImageTap: { imageURL in
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            selectedImageURL = imageURL
                                        }
                                    }
                                )
                                .id(message.id)
                            }
                            
                            if isTextLoading {
                                typingIndicator
                            }
                            
                            if isImageLoading {
                                selfieLoadingIndicator
                            }
                            
                            // Bottom anchor to guarantee scroll covers loaders
                            Color.clear
                                .frame(height: 1)
                                .id("bottomAnchor")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .onChange(of: messages.count) { _ in
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo("bottomAnchor", anchor: .bottom)
                        }
                    }
                    .onChange(of: isTextLoading) { _ in
                        if isTextLoading {
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo("bottomAnchor", anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: isImageLoading) { _ in
                        if isImageLoading {
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo("bottomAnchor", anchor: .bottom)
                            }
                        }
                    }
                    .onAppear {
                        if !messages.isEmpty {
                            Task {
                                // Immediate scroll pass
                                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                                withAnimation(.easeOut(duration: 0.25)) {
                                    proxy.scrollTo("bottomAnchor", anchor: .bottom)
                                }
                                // Second scroll pass (safeguard for slow load/images layout)
                                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds later
                                withAnimation(.easeOut(duration: 0.25)) {
                                    proxy.scrollTo("bottomAnchor", anchor: .bottom)
                                }
                            }
                        }
                    }
                }
                
                // Feature Description Banner
                if showBanner {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.pink)
                        Text(bannerText)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.pink)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.pink.opacity(0.08))
                    .overlay(
                        VStack {
                            Divider()
                            Spacer()
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
                }
                
                // Input bar
                inputBar
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar(.visible, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color(.systemBackground), for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 10) {
                        AsyncImage(url: girlfriend.avatarUrls.primaryURL) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            default:
                                Circle()
                                    .fill(Color.gray.opacity(0.35))
                                    .opacity(isSkeletonPulsing ? 0.3 : 0.85)
                                    .animation(.easeInOut(duration: 0.75).repeatForever(autoreverses: true), value: isSkeletonPulsing)
                                    .onAppear {
                                        isSkeletonPulsing = true
                                    }
                            }
                        }
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text(girlfriend.name)
                                .font(.system(size: 15, weight: .semibold, design: .default))
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 6, height: 6)
                                Text("Online")
                                    .font(.system(size: 11, weight: .medium, design: .default))
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 16))
                        }
                        .foregroundColor(.pink)
                    }
                }
            }
            .onAppear {
                // Force Opaque Navigation Bar Appearance
                let appearance = UINavigationBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = .systemBackground
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
                
                // Register conversation when view appears and get conversationId
                let conversation = chatsVM.startConversation(with: girlfriend, source: source)
                conversationId = conversation.conversationId
                
                // Load saved messages
                let saved = chatsVM.loadMessages(for: conversationId)
                if !saved.isEmpty {
                    self.messages = saved
                } else {
                    addGreeting()
                }
                
                // Start dot cycle animation
                Task {
                    while !Task.isCancelled {
                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                        if isTextLoading || isImageLoading {
                            dotCount = (dotCount % 3) + 1
                        }
                    }
                }
            }
        }
        .fullScreenCover(item: Binding<IdentifiableURL?>(
            get: { selectedImageURL.map { IdentifiableURL(url: $0) } },
            set: { selectedImageURL = $0?.url }
        )) { identifiableURL in
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                if let url = URL(string: identifiableURL.url) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        case .failure(_):
                            VStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white)
                                Text("Failed to load image")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        case .empty:
                            ProgressView()
                                .tint(.white)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .ignoresSafeArea()
                }
                
                // Close button positioned relative to the screen edge respecting safe area
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            selectedImageURL = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                                .background(Circle().fill(Color.black.opacity(0.4)))
                                .padding(.top, 16)
                                .padding(.trailing, 20)
                        }
                    }
                    Spacer()
                }
            }
        }
    }
    
    private var welcomeMessage: some View {
        VStack(spacing: 16) {
            CachedAsyncImage(url: girlfriend.avatarUrls.primaryURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(width: 80, height: 80)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(
                        LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 3
                    )
            )
            
            VStack(spacing: 4) {
                Text("Start chatting with \(girlfriend.name)")
                    .font(.system(size: 17, weight: .semibold, design: .default))
                    .foregroundColor(.primary)
                
                Text(girlfriend.personality)
                    .font(.system(size: 13, weight: .regular, design: .default))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 40)
    }
    
    private var typingIndicator: some View {
        HStack {
            HStack(spacing: 8) {
                Text("typing")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 3) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(Color.gray.opacity(0.6))
                            .frame(width: 5, height: 5)
                            .opacity(dotCount >= index + 1 ? 1.0 : 0.15)
                            .scaleEffect(dotCount >= index + 1 ? 1.0 : 0.7)
                            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: dotCount)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.aiMessageBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            
            Spacer()
        }
    }
    
    private var selfieLoadingIndicator: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.pink)
                
                Text("taking selfie")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.pink)
                
                HStack(spacing: 3) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(Color.pink.opacity(0.6))
                            .frame(width: 5, height: 5)
                            .opacity(dotCount >= index + 1 ? 1.0 : 0.15)
                            .scaleEffect(dotCount >= index + 1 ? 1.0 : 0.7)
                            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: dotCount)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.pink.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.pink.opacity(0.15), lineWidth: 0.5)
            )
            
            Spacer()
        }
    }
    
    private var inputBar: some View {
        HStack(spacing: 12) {
            // Image generation toggle button
            Button(action: {
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                isImageGenerationEnabled.toggle()
                if isImageGenerationEnabled {
                    triggerBanner(message: "Selfie Mode Active: She will reply with a context-matching photo!")
                } else {
                    triggerBanner(message: "Selfie Mode Disabled")
                }
            }) {
                Image(systemName: isImageGenerationEnabled ? "photo.fill" : "photo")
                    .font(.system(size: 24))
                    .foregroundStyle(
                        isImageGenerationEnabled
                            ? AnyShapeStyle(LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                            : AnyShapeStyle(Color.gray)
                    )
            }
            .padding(.leading, 4)
            
            // Text field
            TextField("Type a message...", text: $inputText, axis: .vertical)
                .font(.system(size: 16, weight: .regular, design: .default))
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color(.separator), lineWidth: 0.5)
                )
                .lineLimit(1...5)
                .focused($isInputFocused)
                .submitLabel(.send)
                .onSubmit {
                    sendMessage()
                }
            
            // Send button
            Button(action: sendMessage) {
                Image(systemName: isLoading ? "hourglass" : "arrow.up.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(
                        inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading
                            ? AnyShapeStyle(Color.gray.opacity(0.4))
                            : AnyShapeStyle(LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    )
            }
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
    }
    
    private func appendMessage(_ message: ChatMessage) {
        messages.append(message)
        chatsVM.saveMessages(messages, for: conversationId)
    }
    
    private func triggerBanner(message: String) {
        bannerText = message
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            showBanner = true
        }
        
        // Auto hide after 3 seconds
        let currentMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeInOut(duration: 0.25)) {
                if bannerText == currentMessage {
                    showBanner = false
                }
            }
        }
    }
    
    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isLoading else { return }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Clear input immediately
        inputText = ""
        
        // Add user message
        let userMessage = ChatMessage(text: text, isUser: true, timestamp: Date())
        appendMessage(userMessage)
        
        // Update last message in conversation
        chatsVM.updateLastMessage(for: girlfriend.id, message: text)
        
        // Show typing indicator
        isTextLoading = true
        if isImageGenerationEnabled {
            isImageLoading = true
        }
        isLoading = true
        
        // Send to API
        Task {
            await sendMessageToAPI(text: text)
        }
    }
    
    private func sendMessageToAPI(text: String) async {
        guard !conversationId.isEmpty else { return }
        
        if isImageGenerationEnabled {
            // Run both text and image calls in parallel using separate Tasks
            
            // 1. Trigger Text Response Task
            Task {
                do {
                    let textResponse = try await APIService.shared.sendChatMessage(
                        deviceId: deviceId,
                        conversationId: conversationId,
                        message: text,
                        name: girlfriend.name,
                        age: girlfriend.age,
                        personality: girlfriend.personality,
                        prompt: girlfriend.prompt.isEmpty ? generateDefaultPrompt() : girlfriend.prompt,
                        location: girlfriend.location.displayText,
                        girlfriendId: girlfriend.id,
                        version: appVersion
                    )
                    
                    await MainActor.run {
                        // Only turn off typing/loading state if both have finished (or let them manage individually)
                        // For simplicity, hide indicator when text returns, since image can load asynchronously
                        isTextLoading = false
                        if !isImageLoading {
                            isLoading = false
                        }
                        
                        if let responseText = textResponse.message {
                            let aiTextMessage = ChatMessage(text: responseText, isUser: false, timestamp: Date())
                            appendMessage(aiTextMessage)
                            chatsVM.updateLastMessage(for: girlfriend.id, message: responseText)
                        } else if let error = textResponse.error {
                            let errorMsg = ChatMessage(text: "Failed to load reply: \(error) 💔", isUser: false, isError: true)
                            appendMessage(errorMsg)
                        }
                    }
                } catch {
                    await MainActor.run {
                        isTextLoading = false
                        if !isImageLoading {
                            isLoading = false
                        }
                        let errorMsg = ChatMessage(text: "Connection error 💔", isUser: false, isError: true)
                        appendMessage(errorMsg)
                    }
                }
            }
            
            // 2. Trigger Image Generation Task
            Task {
                do {
                    let imageResponse = try await APIService.shared.sendChatImageMessage(
                        message: text,
                        age: girlfriend.age,
                        personality: girlfriend.personality,
                        location: girlfriend.location.displayText,
                        girlfriendId: girlfriend.id,
                        generateImage: true,
                        version: appVersion
                    )
                    
                    await MainActor.run {
                        isImageLoading = false
                        if !isTextLoading {
                            isLoading = false
                        }
                        
                        if let imageUrl = imageResponse.image, imageResponse.success {
                            // Create pure image bubble with no text description
                            let aiImageMessage = ChatMessage(
                                text: "",
                                isUser: false,
                                timestamp: Date(),
                                imageURL: imageUrl
                            )
                            appendMessage(aiImageMessage)
                        }
                    }
                } catch {
                    await MainActor.run {
                        isImageLoading = false
                        if !isTextLoading {
                            isLoading = false
                        }
                    }
                    // Fail silently for image generation without breaking the conversation flow
                    print("Failed to generate parallel image: \(error.localizedDescription)")
                }
            }
            
        } else {
            // Normal flow: only request text response
            do {
                let response = try await APIService.shared.sendChatMessage(
                    deviceId: deviceId,
                    conversationId: conversationId,
                    message: text,
                    name: girlfriend.name,
                    age: girlfriend.age,
                    personality: girlfriend.personality,
                    prompt: girlfriend.prompt.isEmpty ? generateDefaultPrompt() : girlfriend.prompt,
                    location: girlfriend.location.displayText,
                    girlfriendId: girlfriend.id,
                    version: appVersion
                )
                
                await MainActor.run {
                    isTextLoading = false
                    isLoading = false
                    
                    if let error = response.error {
                        let errorMsg = ChatMessage(
                            text: "Oops! \(error) Tap to retry 💔",
                            isUser: false,
                            isError: true
                        )
                        appendMessage(errorMsg)
                        errorMessage = error
                    } else if let responseText = response.message {
                        let aiMessage = ChatMessage(text: responseText, isUser: false, timestamp: Date())
                        appendMessage(aiMessage)
                        chatsVM.updateLastMessage(for: girlfriend.id, message: responseText)
                        errorMessage = nil
                    } else {
                        let errorMsg = ChatMessage(
                            text: "No response received. Tap to retry 💔",
                            isUser: false,
                            isError: true
                        )
                        appendMessage(errorMsg)
                    }
                }
            } catch {
                await MainActor.run {
                    isTextLoading = false
                    isLoading = false
                    let errorMsg = ChatMessage(
                        text: "Connection error. Tap to retry 💔",
                        isUser: false,
                        isError: true
                    )
                    appendMessage(errorMsg)
                }
            }
        }
    }
    
    private func retryLastMessage() {
        // Find the last user message before the error
        guard let lastUserMessage = messages.last(where: { $0.isUser && !$0.isError }) else {
            return
        }
        
        // Remove error message
        messages.removeAll { $0.isError }
        
        // Retry sending
        isTextLoading = true
        if isImageGenerationEnabled {
            isImageLoading = true
        }
        isLoading = true
        
        Task {
            await sendMessageToAPI(text: lastUserMessage.text)
        }
    }
    
    private func generateDefaultPrompt() -> String {
        return "Keep responses sexy, seductive, playful, cheeky, and tantalizing. Use emojis like 💋,😘,💕. Be mysterious, intriguing and teasing. Keep responses short and engaging."
    }
    
    private func addGreeting() {
        // Only add greeting if no messages yet
        guard messages.isEmpty else { return }
        
        // Show typing indicator and request initial greeting from API
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            await MainActor.run {
                isTextLoading = true
                isLoading = true
            }
            
            // Request a greeting by sending a simple message
            // The API will respond with a contextual greeting
            guard !conversationId.isEmpty else { return }
            
            do {
                let response = try await APIService.shared.sendChatMessage(
                    deviceId: deviceId,
                    conversationId: conversationId,
                    message: "Hi",
                    name: girlfriend.name,
                    age: girlfriend.age,
                    personality: girlfriend.personality,
                    prompt: girlfriend.prompt.isEmpty ? generateDefaultPrompt() : girlfriend.prompt,
                    location: girlfriend.location.displayText,
                    girlfriendId: girlfriend.id,
                    version: appVersion
                )
                
                await MainActor.run {
                    isTextLoading = false
                    isLoading = false
                    
                    if let responseText = response.message {
                        let greeting = ChatMessage(text: responseText, isUser: false, timestamp: Date())
                        appendMessage(greeting)
                        chatsVM.updateLastMessage(for: girlfriend.id, message: responseText)
                    } else {
                        // Fallback greeting if API fails
                        let fallbackGreeting = ChatMessage(
                            text: "Hey there! 😘 I've been waiting for you... 💕",
                            isUser: false,
                            timestamp: Date()
                        )
                        appendMessage(fallbackGreeting)
                    }
                }
            } catch {
                await MainActor.run {
                    isTextLoading = false
                    isLoading = false
                    // Fallback greeting on error
                    let fallbackGreeting = ChatMessage(
                        text: "Hey there! 😘 I've been waiting for you... 💕",
                        isUser: false,
                        timestamp: Date()
                    )
                    appendMessage(fallbackGreeting)
                }
            }
        }
    }
}

struct ChatBubble: View {
    let message: ChatMessage
    let avatarURL: URL?
    var onRetry: (() -> Void)?
    var onImageTap: ((String) -> Void)? = nil
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isUser {
                Spacer(minLength: 60)
            } else {
                AsyncImage(url: avatarURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                    }
                }
                .frame(width: 28, height: 28)
                .clipShape(Circle())
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Group {
                    if message.isError {
                        Button(action: {
                            if let retry = onRetry {
                                retry()
                            }
                        }) {
                            messageBubbleContent
                        }
                        .buttonStyle(.plain)
                    } else {
                        messageBubbleContent
                    }
                }
                
                Text(formatTime(message.timestamp))
                    .font(.system(size: 10, weight: .medium, design: .default))
                    .foregroundColor(Color.secondary)
            }
            
            if !message.isUser {
                Spacer(minLength: 60)
            }
        }
    }
    
    private var messageBubbleContent: some View {
        VStack(alignment: .leading, spacing: message.text.isEmpty ? 0 : 8) {
            if let imageStr = message.imageURL, let url = URL(string: imageStr) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 240, height: 240)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if let onImageTap = onImageTap {
                                    onImageTap(imageStr)
                                }
                            }
                    case .failure(_):
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.title)
                                .foregroundColor(.red)
                            Text("Failed to load image")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 240, height: 240)
                        .background(Color.black.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    case .empty:
                        ProgressView()
                            .frame(width: 240, height: 240)
                            .background(Color.black.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            
            if !message.text.isEmpty {
                Text(message.text)
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .foregroundColor(
                        message.isUser 
                            ? Color.white 
                            : (message.isError 
                                ? Color.red 
                                : Color.aiMessageText)
                    )
            }
        }
        .opacity(1.0)
        .padding(.horizontal, message.text.isEmpty ? 4 : 14)
        .padding(.vertical, message.text.isEmpty ? 4 : 10)
        .background(
            message.isUser
                ? AnyShapeStyle(LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                : message.isError
                    ? AnyShapeStyle(Color.red.opacity(0.15))
                    : AnyShapeStyle(Color.aiMessageBackground)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: message.isUser ? Color.black.opacity(0.1) : Color.clear, radius: 2, x: 0, y: 1)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        ChatView(
            girlfriend: Girlfriend(
                id: "1",
                name: "Sofia",
                age: "24",
                personality: "Adventurous and spontaneous",
                interests: ["Hiking", "Photography"],
                description: "A free-spirited soul...",
                location: GirlfriendLocation(city: "San Francisco", state: "California", country: "USA"),
                avatarUrls: AvatarUrls(image1: "https://picsum.photos/200", image2: nil),
                prompt: ""
            ),
            source: .nearby
        )
    }
}
