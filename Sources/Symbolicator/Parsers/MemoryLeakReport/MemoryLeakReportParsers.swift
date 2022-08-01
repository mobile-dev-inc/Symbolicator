
import Foundation
import Parsing


protocol Symbolizer {
    func getLoadAddress(_: String) -> String
    func getUnsymbolizedAddresses(_: String) -> [String]
}

struct Runner<S: Symbolizer> {
    let symbolizer: S
    let dsymPath: String
    let arch: String
        
    func run(on string: String) -> String {
        var string = string
        let loadAddress = symbolizer.getLoadAddress(string)
        
        for address in symbolizer.getUnsymbolizedAddresses(string) {
            let symbolized = try! atos(dsymPath, arch: arch, loadAddress: loadAddress, address: address)
            print(symbolized)
            
            string = string.replacingOccurrences(of: address + " " + loadAddress, with: address + " " + symbolized)
        }
        
        return string
    }
}

struct MemoryLeakParser: Symbolizer {
    let memoryLeakReport: String
    
    init(_ memoryLeakReport: String) {
        self.memoryLeakReport = memoryLeakReport
    }

    func getLoadAddress(_ string: String) -> String {
        let regex = try! NSRegularExpression(pattern: #"Load Address:\s*(0x[0-9a-fA-F]+)\b"#)

        let range = NSRange(location: 0, length: memoryLeakReport.utf16.count)
        
        guard let match = regex.firstMatch(in: memoryLeakReport, range: range) else {
            fatalError()
        }
        
        let matchRange = match.range(at: 1)
        
        let start = String.Index.init(utf16Offset: matchRange.lowerBound, in: memoryLeakReport)
        let end = String.Index.init(utf16Offset: matchRange.upperBound, in: memoryLeakReport)
        
        return String(memoryLeakReport[start..<end])
    }
    
    func getUnsymbolizedAddresses(_ string: String) -> [String] {
        let loadAddress = getLoadAddress(string)
        
        let regex0 = try! NSRegularExpression(pattern: #"\n----\n"#)
        let fullStringRange = NSRange(location: 0, length: memoryLeakReport.utf16.count)
        guard let match0 = regex0.firstMatch(in: memoryLeakReport, range: fullStringRange) else {
            fatalError()
        }
        
        let regex1 = try! NSRegularExpression(pattern: #"Binary Images:"#)
        guard let match1 = regex1.firstMatch(in: memoryLeakReport, range: fullStringRange) else {
            fatalError()
        }
        
        // Search after the headers and before the Binary Images
        let range = NSRange(
            location: match0.range.upperBound,
            length: match1.range.lowerBound)
        
        // Mach: 0x6000024250e0
        // But don't match: <LeakySwiftObject 0x6000024250e0>
        let regex = try! NSRegularExpression(pattern: #"(0x[0-9a-fA-F]+) \#(loadAddress) +"#)
        
        
        let matches = regex.matches(
            in: memoryLeakReport,
            options: [],
            range: range)
                
        let result = matches.map { match -> String in
            let range = match.range(at: 1)
            
            let start = String.Index.init(utf16Offset: range.lowerBound, in: memoryLeakReport)
            let end = String.Index.init(utf16Offset: range.upperBound, in: memoryLeakReport)
            
            return String(memoryLeakReport[start..<end])
        }
        
        return Array(Set(result))
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
