
import Foundation
import Parsing

struct MemoryLeakParser {
    let data: Data
    
    func parse() -> MemoryLeakReport? {
        guard let string = String(data: data, encoding: .utf8),
              string.starts(with: "Process:")
        else { return nil }

        var str = string[...]
        let result = try! MemoryLeakReportParse().parse(&str)
        print(result)
        return result
    }
}

struct MemoryLeakReportParse: Parser {
    func parse(_ input: inout Substring) throws -> MemoryLeakReport {
        let (headers, metadata, leaks, rest) = try Parse {
            HeadersParse()
            MetadataParse()
            
            Many {
                LeakParse()
            }

            Rest()
        }
        .parse(&input)
        
        print("REST")
        print(rest)
        
        return MemoryLeakReport(
            headers: headers.toString,
            metadata: metadata.toString,
            leaks: leaks)
    }
}

private extension Dictionary where Key == Substring, Value == Substring {
    var toString: Dictionary<String, String> {
        Dictionary<String, String>(uniqueKeysWithValues: map { key, value in
            (String(key), String(value))
        })
    }
}
