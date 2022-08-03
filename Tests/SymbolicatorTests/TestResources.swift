import Foundation

class TestResources {
    static let shared = TestResources()
    
    let memoryLeakNoStackUrl = Bundle.module.url(forResource: "memory_leak_no_stack", withExtension: "txt")!
    let memoryLeakUnsymbolicatedUrl = Bundle.module.url(forResource: "memory_leak_unsymbolicated", withExtension: "txt")!
    let memoryLeakWithStacktraceUrl = Bundle.module.url(forResource: "memory_leak_with_stacktrace", withExtension: "txt")!
    let memoryLeakWithSymbolicatedStacktraceUrl = Bundle.module.url(forResource: "memory_leak_with_symbolicated_stacktrace", withExtension: "txt")!
    let memoryLeakUnicodeUnsymbolicatedUrl = Bundle.module.url(forResource: "memory_leak_unicode_unsymbolicated", withExtension: "txt")!
    
    let dsymUrl = Bundle.module.url(forResource: "MemoryLeakingApp.app", withExtension: "dSYM")!
    let nonSymbolicatedCrashUrl = Bundle.module.url(forResource: "non_symbolicated_crash", withExtension: "crash")!
    let crashDsymUrl = Bundle.module.url(forResource: "crash.app", withExtension: "dSYM")!
}
