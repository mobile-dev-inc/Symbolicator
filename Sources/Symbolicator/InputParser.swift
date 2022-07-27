
import Foundation
import Parsing

struct MemoryLeakParser {
        
    let data: Data
    
    func parse() -> MemoryLeakReport? {
        guard let string = String(data: data, encoding: .utf8),
              string.starts(with: "Process:")
        else { return nil }
        
        let headerParser = Parse {
            Prefix { $0 != ":" && $0 != "\n" }
            ":"
            Skip { Whitespace(.horizontal) }
            Prefix { $0 != "\n" }
        }
        
        let headersParser = Many {
            Skip { Many { "\n" } }
            headerParser
        } terminator: { "\n----" }
        
        let metadataParser = Many {
            Skip { "\n" }
            headerParser
        } terminator: { "\n\n" }
        
        let cycleObjectPrefixParser = Parse {
            Whitespace(.vertical)
            Int.parser()
            "("
            Int.parser()
            " bytes)"
        }
        
        let objectDescriptionParser = Parse {
            
            "["
            Int.parser()
            "]"
        }
        
        let cycleTotalParser = Parse {
            cycleObjectPrefixParser
            Whitespace()
            "<< TOTAL >>"
        }
        
        let cycleRootParser = Parse {
            cycleObjectPrefixParser
            Whitespace()
            "ROOT LEAK:"
            Whitespace()
            
        }
        
     
        
        let reportParser = Parse {
            headersParser
            "\n"
            metadataParser
            Rest()
        }
        
        
        
        let result = try! reportParser.parse(string)
        print(result)
        
        
        var lines = string.split(separator: "\n", omittingEmptySubsequences: false)
    
        let headers = parseHeaders(from: &lines)
        let metadata = parseMetadata(from: &lines)
        
        
        var leaks = [MemoryLeakReport.Leak]()
        let leak = parseLeak(from: &lines)
        leaks.append(leak)
        
        return MemoryLeakReport(
            headers: headers,
            metadata: metadata,
            leaks: leaks)
    }
    
    func parseHeaders(from lines: inout [Substring]) -> [String: String] {
        var headers = [String: String]()
        
        while !lines.isEmpty {
            let line = lines.removeFirst()
            guard line != "----" else {
                return headers
            }
            
            guard !line.isEmpty else {
                continue
            }
            
            guard line.contains(":") else {
                return headers
            }
            
            let parts = line.split(separator: ":")
            headers[String(parts[0])] = String(parts[1])
        }
        
        return headers
    }
    
    func parseMetadata(from lines: inout [Substring]) -> [String: String] {
        var metadata = [String: String]()
        
        // Skip the first empty line(s)
        while lines.first?.isEmpty ?? false {
            lines.removeFirst()
        }
        
        while !lines.isEmpty {
            let line = lines.removeFirst()
            guard line != "" && line.contains(":") else {
                return metadata
            }
            
            let parts = line.split(separator: ":")
            metadata[String(parts[0])] = String(parts[1]).trimWhitespace()
        }
        
        return metadata
    }
    
    func parseLeak(from lines: inout [Substring]) -> MemoryLeakReport.Leak {
        let stack = parseStackTrace(from: &lines)
        
        var cycle = [MemoryLeakReport.CycleLine]()
        while !lines.isEmpty {
            let line = lines.removeFirst()
            guard !line.isEmpty else {
                break
            }
            
            let cycleLine = parseLeakCycleLine(from: line)
            cycle.append(cycleLine)
        }
        
        return MemoryLeakReport.Leak(
            stack: stack,
            cycle: cycle)
    }

    func parseStackTrace(from lines: inout [Substring]) -> MemoryLeakReport.Stack? {
        guard lines.first?.starts(with: "STACK") ?? false else {
            return nil
        }
        
        let stack = MemoryLeakReport.Stack()
        
        lines.removeFirst()
        
        while !lines.isEmpty {
            let line = lines.removeFirst()
            guard line != "====" else {
                return stack
            }
        }
        
        return stack
    }
    

    func parseLeakCycleLine(from line: Substring) -> MemoryLeakReport.CycleLine {
        //"     4 (272 bytes) ROOT CYCLE: 0x7ff29c304500 [16]

        let base = #"\w+(\d+)\w\([^)]\)"#
        let object = #"([^][]) \[\(\d+)\](?: length: (\d+) ?(\w*))"#
        
        let total = try! NSRegularExpression(pattern: base + " << TOTAL >>")
        let separator = try! NSRegularExpression(pattern: #"\w+----"#)
        
        let rootCycle = try! NSRegularExpression(pattern: base + "ROOT CYCLE: " + object)
        let rootLeak = try! NSRegularExpression(pattern: base + "ROOT LEAK: " + object)
        
        
        
        return MemoryLeakReport.CycleLine()
    }
}

extension StringProtocol {
    func trimWhitespace() -> Self {
        Self(trimmingCharacters(in: .whitespacesAndNewlines))!
    }
}
