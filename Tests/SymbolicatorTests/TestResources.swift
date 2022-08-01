import Foundation

class TestResources {
    static let shared = TestResources()
    
    let memoryLeakUrl = Bundle.module.url(forResource: "memory_leak", withExtension: "txt")!
    let memoryLeakWithStacktraceUrl = Bundle.module.url(forResource: "memory_leak_with_stacktrace", withExtension: "txt")
    let memoryLeakWithSymbolicatedStacktraceUrl = Bundle.module.url(forResource: "memory_leak_with_symbolicated_stacktrace", withExtension: "txt")
    let memoryLeakWithUnsymbolicatedStacktraceUrl = Bundle.module.url(forResource: "memory_leak_with_unsymbolicated_stacktrace", withExtension: "txt")
    let dsymUrl = Bundle.module.url(forResource: "MemoryLeakingApp.app", withExtension: "dSYM")!
    let nonSymbolicatedCrashUrl = Bundle.module.url(forResource: "non_symbolicated_crash", withExtension: "crash")!
    let crashDsymUrl = Bundle.module.url(forResource: "crash.app", withExtension: "dSYM")!
}
