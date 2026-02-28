import Foundation

class GeminiService {
    static let shared = GeminiService()
    
    private init() {}
    
    /// Transmits the high-res JSON payload to the Hybrid Evolution v3 prompt via native REST
    func analyzeSession(payload: String) async throws -> String {
        // 1. Construct the secure endpoint using your APIKey vault
        let apiKey = APIKey.defaultKey
        let endpointString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=\(apiKey)"
        
        
        guard let url = URL(string: endpointString) else {
            throw URLError(.badURL)
        }
        
        // 2. Format the payload to match Google's required JSON structure
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": payload]
                    ]
                ]
            ]
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        
        // 3. Configure the HTTP Request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        // 4. Execute the network call
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // 5. Validate the response status
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown server fault"
            throw NSError(domain: "GeminiService", code: 1, userInfo: [NSLocalizedDescriptionKey: "API Error: \(errorMsg)"])
        }
        
        // 6. Parse the JSON response to extract the coach's text
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let candidates = json["candidates"] as? [[String: Any]],
           let firstCandidate = candidates.first,
           let content = firstCandidate["content"] as? [String: Any],
           let parts = content["parts"] as? [[String: Any]],
           let firstPart = parts.first,
           let text = firstPart["text"] as? String {
            return text
        }
        
        throw URLError(.cannotParseResponse)
    }
}
