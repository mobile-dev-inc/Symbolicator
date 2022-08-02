import Foundation

struct MemoryLeakReportSymbolicator: Symbolicator {
    let memoryLeakReport: String
    
    init(_ memoryLeakReport: String) {
        self.memoryLeakReport = memoryLeakReport
    }

    func getLoadAddress() -> String {
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
    
    func getUnsymbolizedAddresses() -> [String] {
        let loadAddress = getLoadAddress()
        
        let memoryLeakReportRangeEnd = memoryLeakReport.endIndex.utf16Offset(in: memoryLeakReport)
        let fullStringRange = NSRange(location: 0, length: memoryLeakReportRangeEnd)

        let regex0 = try! NSRegularExpression(pattern: #"\n----\n"#)
        guard let match0 = regex0.firstMatch(in: memoryLeakReport, range: fullStringRange) else {
            fatalError()
        }
        let location = match0.range.upperBound
        
        let length: Int
        if let regex1 = try? NSRegularExpression(pattern: #"Binary Images:"#),
            let match1 = regex1.firstMatch(in: memoryLeakReport, range: fullStringRange)  {
            length = match1.range.lowerBound - location
        } else {
            length = memoryLeakReportRangeEnd - location
        }
        
        // Search after the headers and before the Binary Images
        let range = NSRange(
            location: location,
            length: length)
        
        // Mach: 0x6000024250e0
        // But don't match: <LeakySwiftObject 0x6000024250e0>
        let regex = try! NSRegularExpression(pattern: #"(0x[0-9a-fA-F]+) \#(loadAddress) +"#)
        
        
        let matches = regex.matches(
            in: memoryLeakReport,
            options: [],
            range: range)
                
        let result = matches.map { match -> String in
            let range = Range(match.range(at: 1), in: memoryLeakReport)!
            return String(memoryLeakReport[range])
        }
        
        return Array(Set(result))
    }
}
