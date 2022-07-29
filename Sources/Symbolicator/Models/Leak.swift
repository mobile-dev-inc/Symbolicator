import Foundation

struct Leak {
    let stack: Stack?
    let cycle: [LeakCycle]
}
