// QuoteService.swift
import Foundation
import Combine

@MainActor
class QuoteService: ObservableObject {
    @Published var currentQuote: Quote?
    @Published var isLoading = false
    @Published var error: String?
    
    private let apiURL = "https://zenquotes.io/api/today"
    
    func fetchDailyQuote() async {
        isLoading = true
        error = nil
        
        do {
            guard let url = URL(string: apiURL) else {
                throw QuoteError.invalidURL
            }
            
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw QuoteError.invalidResponse
            }
            
            let quotes = try JSONDecoder().decode([Quote].self, from: data)
            
            if let firstQuote = quotes.first {
                currentQuote = firstQuote
            } else {
                throw QuoteError.noQuoteFound
            }
            
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
            // Provide a fallback quote
            currentQuote = Quote(
                q: "Every day is a new opportunity to capture your journey.",
                a: "Anonymous",
                h: nil
            )
        }
    }
}

enum QuoteError: LocalizedError {
    case invalidURL
    case invalidResponse
    case noQuoteFound
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid server response"
        case .noQuoteFound:
            return "No quote found"
        }
    }
}
