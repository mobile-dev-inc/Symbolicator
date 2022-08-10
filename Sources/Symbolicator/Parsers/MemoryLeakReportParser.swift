import Foundation
import Parsing

struct MemoryLeakReportParser: Parser {
    func parse(_ input: inout Substring) throws -> MemoryLeakReport {
        try Parse {
            Parse {
                PrefixUpTo("\nleaks Report Version:")
                PrefixUpTo("\n\n")

                Whitespace()
            }

            Many {
                Not { "\n\n" }
                LeakParser()
            }
            
            Whitespace()

            Optionally {
                Int.parser()
                " leaks excluded"
                Skip { PrefixThrough("\n\n\n") }
            }

            Optionally {
                Rest().map { String($0) }
            }
        }
        .map {
            MemoryLeakReport(
                headers: String($0.0.0) + String($0.0.1),
                leaks: $0.1,
                excludedLinkCount: $0.2 ?? 0,
                binaryImages: $0.3
            )
        }
        .parse(&input)
    }
}
