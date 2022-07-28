import Foundation

protocol CrashFileParsing {
    mutating func parse() throws -> CrashFileParserResult
}

enum CrashFileParserError: Error {
    case emptyFile
}

struct CrashFileParser: CrashFileParsing {
    private enum Constant {
        static let symbolicatedAppName = "ReportCrash"
        static let dwarfFilePath = "/Contents/Resources/DWARF/"
    }
    
    private let data: Data
    private let appName: String
    private let dsymPath: String
    
    init(data: Data, appName: String, dsymPath: String) {
        self.data = data
        self.appName = appName
        self.dsymPath = dsymPath
    }
    
    mutating func parse() throws -> CrashFileParserResult {
        let contentsString = String(data: data,
                                    encoding: .utf8)
        
        guard let contentsString = contentsString, !contentsString.isEmpty else {
            throw CrashFileParserError.emptyFile
        }
        
        let lines = contentsString.components(separatedBy: .newlines)
        
        var thread: ThreadBlock?
        var threads: [ThreadBlock] = []
        
        let symbolicatedLines = lines.map { line -> String in
            var symbolicatedLine = line
            
            if line.contains(Constant.symbolicatedAppName) {
                symbolicatedLine = line.replacingOccurrences(of: Constant.symbolicatedAppName,
                                                             with: appName)
            }
            
            if symbolicatedLine ~= "^Thread" {
                thread = ThreadBlock(header: symbolicatedLine, appName: appName)
            } else if thread != nil && symbolicatedLine ~= "^\\d+ " {
                if symbolicatedLine.contains(appName) {
                    let segments = symbolicatedLine.split(separator: " ").map { String($0) }
                    
                    if segments.count >= 4 {
                        let (address, loadAddress) = (segments[2],
                                                      segments[3])
                        
                        do {
                            let symbolicatedAddress = try atos("\(dsymPath)\(Constant.dwarfFilePath)\(appName)",
                                                               arch: "x86_64",
                                                               loadAddress: loadAddress,
                                                               address: address)
                            symbolicatedLine = symbolicatedLine.replacingOccurrences(of: loadAddress,
                                                                                     with: symbolicatedAddress)
                        } catch {
                            // soft fail in case symbolication fails
                            debugPrint("atos command failed with error - \(error)")
                        }
                        
                        thread?.appendLine(line: symbolicatedLine)
                    }
                } else {
                    thread?.appendLine(line: symbolicatedLine)
                }
            } else {
                if let thread = thread, symbolicatedLine.isEmpty {
                    threads.append(thread)
                }
                
                thread = nil
            }
            
            return symbolicatedLine
        }
        
        return CrashFileParserResult(contents: symbolicatedLines.joined(separator: "\n"),
                                     threads: threads)
    }
}
