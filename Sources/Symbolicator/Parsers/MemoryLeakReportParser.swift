import Foundation
import Parsing

struct MemoryLeakReportParser: Parser {
    func parse(_ input: inout Substring) throws -> MemoryLeakReport {
        try Parse {
            PrefixUpTo("\nleaks Report Version:").map { String($0) }
            PrefixUpTo("\n\n").map { String($0) }
 
            Whitespace()
            
            Many {
                Not { "\n\n\n" }
                LeakParser()
            }
            
            Whitespace()
            
            Optionally {
                Rest().map { String($0) }
            }
        }
        .map {
            MemoryLeakReport(
                headers: $0.0 + $0.1,
                leaks: $0.2,
                binaryImages: $0.3
            )
        }
        .parse(&input)
    }
}
