import Foundation

struct LeakCycle {
    let graph: [LeakCycleStep]
}

struct LeakCycleStep {
    let accumulatedObjectCount: Int?
    let accumulatedSize: Int?
    let description: String?
    let address: Int
}
