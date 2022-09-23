import Foundation
import GenericJSON

private let newline = Character("\n").asciiValue!
private let curlyOpen = Character("{").asciiValue!
private let curlyClose = Character("}").asciiValue!

struct IPSSymbolicator: SymbolicatorProtocol {

    private(set) var header: JSON
    private(set) var body: JSON

    init?(_ contents: Data) {
        guard contents.starts(with: [curlyOpen]) else { return nil }
        guard let newlineIndex = contents.firstIndex(of: newline) else { return nil }

        let decoder = JSONDecoder()

        do {
            header = try decoder.decode(JSON.self, from: contents[..<newlineIndex])
            body = try decoder.decode(JSON.self, from: contents[newlineIndex...])
        } catch {
            printStderr("IPS symbolication failed \(error.localizedDescription)")
            return nil
        }
    }

    mutating func setAppName(_ appName: String) {
        fatalError()
    }

    func stackFramesToSymbolize() throws -> [StackFrame] {
        guard let threads = body["threads"]?.arrayValue else {
            throw SymbolicatorError("Expected 'threads' to contain an array in IPS data")
        }

        return try threads.enumerated().flatMap { (threadIndex, thread) -> [StackFrame] in
            guard let frames = thread["frames"]?.arrayValue else {
                throw SymbolicatorError("Expected 'frames' to contain an array in IPS data")
            }

            return try frames.enumerated().compactMap { (frameIndex, frame) -> StackFrame? in
                if frame["symbol"]?.stringValue != nil { return nil }

                guard
                    let usedImages = body["usedImages"]?.arrayValue,
                    let imageIndexDouble = frame["imageIndex"]?.doubleValue,
                    let image = usedImages[Int(imageIndexDouble)].objectValue,
                    let baseDouble = image["base"]?.doubleValue
                else {
                    throw SymbolicatorError("Expected fileds not found in IPS data")
                }

                let base = Int(baseDouble)

                let imageOffset = Int(frame["imageOffset"]!.doubleValue!)

                return StackFrame(tag: "\(threadIndex):\(frameIndex)", base: base, offset: imageOffset)
            }
        }
    }

    mutating func addSymbolsToStackFrames(_ stackFrames: [(StackFrame, String)]) {
        for (address, symbol) in stackFrames {
            let split = address.tag.split(separator: ":").map { Int($0)! }
            let (threadIndex, frameIndex) = (split[0], split[1])

            body["threads"]?
                .arrayValue?[threadIndex]["frames"]?
                .arrayValue?[frameIndex]["symbol"] = JSON.string(symbol)
        }
    }

    var contents: Data {
        var contents = try! JSONEncoder().encode(header)

        contents.append(contentsOf: [newline])

        let bodyEncoder = JSONEncoder()
        bodyEncoder.outputFormatting = .prettyPrinted
        contents.append(try! bodyEncoder.encode(body))

        return contents
    }

    var jsonContents: Data {
        fatalError()
    }
}
