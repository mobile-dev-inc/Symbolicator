import Foundation

struct MemoryLeakReport: Codable {
    let headers: String
    let leaks: [Leak]
    let excludedLeakCount: Int
    let binaryImages: String?

    init(headers: String, leaks: [Leak], excludedLeakCount: Int, binaryImages: String?) {
        self.headers = headers
        self.leaks = leaks
        self.excludedLeakCount = excludedLeakCount
        self.binaryImages = binaryImages
    }
}
