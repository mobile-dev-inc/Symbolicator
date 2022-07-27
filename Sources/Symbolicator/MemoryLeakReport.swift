
import Foundation

struct MemoryLeakReport {
    struct Stack {}
    
    struct CycleLine {
        
    }
    
    struct Leak {
        let stack: Stack?
        let cycle: [CycleLine]
    }
    
    let headers: [String: String]
    let metadata: [String: String]
    let leaks: [Leak]
}
