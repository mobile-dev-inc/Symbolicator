
import Foundation
import Parsing


struct MemoryLeakParser: Symbolicator {
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
