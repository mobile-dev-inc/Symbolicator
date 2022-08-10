import Foundation

struct MemoryLeakReport: Codable {
    let headers: String
    let leaks: [Leak]
    let excludedLeakCount: Int
    let binaryImages: String?

    init(headers: String, leaks: [Leak], excludedLinkCount: Int, binaryImages: String?) {
        self.headers = headers
        self.leaks = leaks
        self.excludedLeakCount = excludedLinkCount
        self.binaryImages = binaryImages
    }
}
