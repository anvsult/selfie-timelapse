// Quote.swift
import Foundation

struct Quote: Codable, Identifiable {
    let id = UUID()
    let q: String  // Quote text
    let a: String  // Author
    let h: String? // HTML formatted quote (optional)
    
    var text: String { q }
    var author: String { a }
    
    enum CodingKeys: String, CodingKey {
        case q, a, h
    }
}

struct QuoteResponse: Codable {
    let quotes: [Quote]
}
