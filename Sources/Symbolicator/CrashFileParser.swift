import Foundation

protocol CrashFileParsing {
    func parse() throws
}

enum CrashFileParserError: Error {
    case emptyFile
}

struct CrashFileParser: CrashFileParsing {
    private enum Constant {
        static let symbolicatedAppName = "ReportCrash"
    }
    
    private let data: Data
    private let appName: String
    
    init(data: Data, appName: String) {
        self.data = data
        self.appName = appName
    }
    
    func parse() throws {
        let contentsString = String(data: data,
                                    encoding: .utf8)
        
        guard let contentsString = contentsString, !contentsString.isEmpty else {
            throw CrashFileParserError.emptyFile
        }
        
        let lines = contentsString.components(separatedBy: .newlines)
        
        let symbolicatedLines = lines.map { line -> String in
            guard !line.contains(Constant.symbolicatedAppName) else {
                return line.replacingOccurrences(of: Constant.symbolicatedAppName,
                                                 with: appName)
            }
            
            return line
        }
        
        print(symbolicatedLines)
    }
}
