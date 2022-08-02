import Foundation

struct MemoryLeakReport {
    let headers: String
    let leaks: [Leak]

    init(headers: String, leaks: [Leak]) {
        self.headers = headers
        self.leaks = leaks
    }
}
