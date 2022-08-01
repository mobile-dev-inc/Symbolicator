import Foundation

struct LeakCycle {
    let steps: [LeakCycleStep]
}

struct LeakCycleStep {
    let count: Int?
    let size: Int?
    let description: String?
    let address: Int
}
