import Foundation

struct NOAAPredictionsResponse: Decodable, Sendable {
    let predictions: [NOAAPredictionEntry]
}

struct NOAAPredictionEntry: Decodable, Sendable {
    let t: String
    let v: String
    let type: String?
}