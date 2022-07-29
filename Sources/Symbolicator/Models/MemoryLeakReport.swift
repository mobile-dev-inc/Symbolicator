import Foundation

struct MemoryLeakReport {
    let headers: [String: String]
    let metadata: [String: String]
    let leaks: [Leak]
}
