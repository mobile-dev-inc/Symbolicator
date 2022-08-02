import Foundation

struct MemoryLeakReport: Codable {
    let headers: String
    let leaks: [Leak]
    let binaryImages: String?

    init(headers: String, leaks: [Leak], binaryImages: String?) {
        self.headers = headers
        self.leaks = leaks
        self.binaryImages = binaryImages
    }
}
