import Foundation

class TestResources {
    static let shared = TestResources()
    
    let memoryLeakUrl = Bundle.module.url(forResource: "memory_leak", withExtension: "txt")!
    let dsymUrl = Bundle.module.url(forResource: "MemoryLeakingApp.app", withExtension: "dSYM")!
    let nonSymbolicatedCrashUrl = Bundle.module.url(forResource: "non_symbolicated_crash", withExtension: "crash")!
}
