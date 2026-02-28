//
//  GeminiService.swift
//  DragsterOS
//
//  Created by James Parker on 28/02/2026.
//


import Foundation
import GoogleGenerativeAI

class GeminiService {
    static let shared = GeminiService()
    private let model: GenerativeModel
    
    private init() {
        // Initializes the fast, cost-effective Flash model using your secure key
        self.model = GenerativeModel(
            name: "gemini-3-flash",
            apiKey: APIKey.defaultKey
        )
    }
    
    /// Transmits the high-res JSON payload to the Hybrid Evolution v3 prompt
    func analyzeSession(payload: String) async throws -> String {
        let response = try await model.generateContent(payload)
        return response.text ?? "The coach is currently contemplative. Please try again."
    }
}