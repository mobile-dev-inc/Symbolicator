import XCTest
import class Foundation.Bundle
@testable import Symbolicator
import Parsing

final class MemoryLeakParserTests: XCTestCase {
    func testParseHeaders() throws {
        let data = try Data(contentsOf: TestResounces().memoryLeakUrl)
        let report = MemoryLeakParser(data: data).parse()
        XCTAssertEqual(report?.headers["Identifier"], "MemoryLeakingApp")
    }

    func testParseMetadata() throws {
        let data = try Data(contentsOf: TestResounces().memoryLeakUrl)
        let report = MemoryLeakParser(data: data).parse()
        XCTAssertEqual(report?.metadata["leaks Report Version"], "4.0")
    }
}

final class SingleHeaderParseTests: XCTestCase {
    func test() throws {
        let input = "Process:         MemoryLeakingApp [14968]"
        
        let header = try SingleHeaderParse().parse(input)
        
        XCTAssertEqual(header.0, "Process")
        XCTAssertEqual(header.1, "MemoryLeakingApp [14968]")
    }
}

final class HeadersParseTests: XCTestCase {
    func test() throws {
        let input = """
            Code Type:       X86-64
            Platform:        iOS Simulator
            Parent Process:  launchd_sim [12679]

            Date/Time:       2022-07-26 12:11:47.963 +0400
            Launch Time:     2022-07-25 19:25:29.886 +0400
            OS Version:      iPhone OS 15.5 (19F70)
            ----
            """
        
        let headers = try HeadersParse().parse(input)
        
        XCTAssertEqual(headers.count, 6)
        XCTAssertEqual(headers["OS Version"], "iPhone OS 15.5 (19F70)")
    }
}

final class MetadataParseTests: XCTestCase {
    func test() throws {
        let input = """
            
            
            leaks Report Version: 4.0
            Process 14968: 32077 nodes malloced for 6030 KB
            Process 14968: 2 leaks for 64 total leaked bytes.
            
            
            """
        
        let metadata = try MetadataParse().parse(input)

        XCTAssertEqual(metadata.count, 2)
        XCTAssertEqual(metadata["leaks Report Version"], "4.0")
        XCTAssertEqual(metadata["Process 14968"], "32077 nodes malloced for 6030 KB\n2 leaks for 64 total leaked bytes.")
    }
}

final class HexDecimalParseTests: XCTestCase {
    func test() throws {
        let input = "0x10f00c1ee"

        let int = try HexDecimalParse().parse(input)
        
        XCTAssertEqual(int, 4546675182)
    }
}

final class StackFrameParseTests: XCTestCase {
    func testUnsymbolicated() throws {
        let input = "41  com.customer.inhouse.dev                0x105a7cd51 0x105a52000 + 175441"
        
        let frame = try StackFrameParse().parse(input)
        
        XCTAssertEqual(frame.stackIndex, 41)
        XCTAssertEqual(frame.frameworkName, "com.customer.inhouse.dev")
        XCTAssertEqual(frame.address, 4389850449)
        XCTAssertEqual(frame.loadAddress, 4389675008)
        XCTAssertNil(frame.name)
        XCTAssertEqual(frame.offset, 175441)
    }
    
    func testSymbolicated() throws {
        let input = "30  com.apple.UIKitCore                   0x133c712b5 UIApplicationMain + 101"
        
        let frame = try StackFrameParse().parse(input)
        
        XCTAssertEqual(frame.stackIndex, 30)
        XCTAssertEqual(frame.frameworkName, "com.apple.UIKitCore")
        XCTAssertEqual(frame.address, 5163651765)
        XCTAssertNil(frame.loadAddress)
        XCTAssertEqual(frame.name, "UIApplicationMain")
        XCTAssertEqual(frame.offset, 101)
    }
    
    func testWithOrigin() throws {
        let input = "7   dev.mobile.MemoryLeakingApp           0x10f00d542 SwiftActionHandler.doAfterRecursing(action:depth:) + 34  SwiftActionHandler.swift:37"
        
        let frame = try StackFrameParse().parse(input)
        
        XCTAssertEqual(frame.origin, "SwiftActionHandler.swift:37")
    }
}

final class StackParseTests: XCTestCase {
    func test() throws {
        let input = """
            STACK OF 2 INSTANCES OF 'ROOT CYCLE: <LeakySwiftObject>':
            36  dyld                                  0x118e1d51e start + 462
            35  dyld_sim                              0x10f242f21 start_sim + 10
            34  dev.mobile.MemoryLeakingApp           0x10f00c1ee main + 30  <compiler-generated>:0
            33  com.apple.SwiftUI                     0x119309854 static App.main() + 61
            32  com.apple.SwiftUI                     0x119946d97 runApp<A>(_:) + 148
            31  com.apple.SwiftUI                     0x119946e5d closure #1 in KitRendererCommon(_:) + 196
            30  com.apple.UIKitCore                   0x133c712b5 UIApplicationMain + 101
            29  com.apple.UIKitCore                   0x133c6c65a -[UIApplication _run] + 928
            28  com.apple.GraphicsServices            0x11294dc8e GSEventRunModal + 139
            27  com.apple.CoreFoundation              0x10f452704 CFRunLoopRunSpecific + 562
            26  com.apple.CoreFoundation              0x10f45304d __CFRunLoopRun + 1100
            25  com.apple.CoreFoundation              0x10f452ab5 __CFRunLoopDoObservers + 570
            24  com.apple.CoreFoundation              0x10f4582f1 __CFRUNLOOP_IS_CALLING_OUT_TO_AN_OBSERVER_CALLBACK_FUNCTION__ + 23
            23  com.apple.UIKitCore                   0x133c9f612 _afterCACommitHandler + 72
            22  com.apple.UIKitCore                   0x133c6b0d9 _cleanUpAfterCAFlushAndRunDeferredBlocks + 135
            21  com.apple.UIKitCore                   0x133c7b809 _runAfterCACommitDeferredBlocks + 782
            20  com.apple.UIKitCore                   0x1341ce6a1 -[_UIAfterCACommitQueue flush] + 190
            19  com.apple.UIKitCore                   0x1341ce1a9 -[_UIAfterCACommitBlock run] + 54
            18  com.apple.UIKitCore                   0x133ebda87 -[UITableView _userSelectRowAtPendingSelectionIndexPath:] + 341
            17  com.apple.UIKitCore                   0x133ebcff9 -[UITableView _selectRowAtIndexPath:animated:scrollPosition:notifyDelegate:] + 94
            16  com.apple.UIKitCore                   0x133ebd7be -[UITableView _selectRowAtIndexPath:animated:scrollPosition:notifyDelegate:isCellMultiSelect:deselectPrevious:] + 1962
            15  com.apple.SwiftUI                     0x119b1a3bd @objc UITableViewListCoordinator.tableView(_:didSelectRowAt:) + 129
            14  com.apple.SwiftUI                     0x119b19c25 UITableViewListCoordinator.tableView(_:didSelectRowAt:) + 545
            13  com.apple.SwiftUI                     0x1194bf055 specialized closure #2 in PlatformItemList.containerSelectionBehavior.getter + 53
            12  com.apple.SwiftUI                     0x1194c65cb thunk for @escaping @callee_guaranteed () -> ()partial apply + 9
            11  com.apple.SwiftUI                     0x1194c5a13 partial apply for thunk for @escaping @callee_guaranteed () -> () + 17
            10  com.apple.SwiftUI                     0x119382a1e thunk for @escaping @callee_guaranteed () -> () + 12
            9   com.apple.SwiftUI                     0x11955c5eb partial apply for implicit closure #2 in implicit closure #1 in DefaultListButtonStyle.ListButton.body.getter + 17
            8   dev.mobile.MemoryLeakingApp           0x10f00e86d closure #2 in closure #1 in closure #1 in closure #1 in ContentView.body.getter + 141  ContentView.swift:44
            7   dev.mobile.MemoryLeakingApp           0x10f00d542 SwiftActionHandler.doAfterRecursing(action:depth:) + 34  SwiftActionHandler.swift:37
            6   dev.mobile.MemoryLeakingApp           0x10f00e89b closure #1 in closure #2 in closure #1 in closure #1 in closure #1 in ContentView.body.getter + 11  <compiler-generated>:0
            5   dev.mobile.MemoryLeakingApp           0x10f00c35c specialized LeakySwiftObject.__allocating_init(cycle:) + 44  LeakySwiftObject.swift:0
            4   dev.mobile.MemoryLeakingApp           0x10f00c283 specialized LeakySwiftObject.init(cycle:) + 51  LeakySwiftObject.swift:16
            3   dev.mobile.MemoryLeakingApp           0x10f00c351 specialized LeakySwiftObject.__allocating_init(cycle:) + 33  LeakySwiftObject.swift:14
            2   libswiftCore.dylib                    0x1116b0777 swift_allocObject + 39
            1   libswiftCore.dylib                    0x1116b0608 swift_slowAlloc + 40
            0   libsystem_malloc.dylib                0x110e0dd91 _malloc_zone_malloc + 241
            ====
            """
        
        let stack = try StackParse().parse(input)
        
        XCTAssertEqual(stack.context, "STACK OF 2 INSTANCES OF 'ROOT CYCLE: <LeakySwiftObject>':")
        XCTAssertEqual(stack.frames.count, 37)
    }
}

final class CycleSymbolicatedObjectParseTests: XCTestCase {
    func test() throws {
        let input = "<LeakyObjcObject 0x600002678b80>"
        let symbol = try CycleSymbolicatedObjectParse().parse(input)
            
        XCTAssertEqual(symbol.0, "LeakyObjcObject")
        XCTAssertEqual(symbol.1, 105553156606848)
    }
}

final class CycleObjectDescriptionParseTests: XCTestCase {
    func testUnsymbolicated() throws {
        let input = "0x6000013746e0 [176]"
        
        let description = try CycleObjectDescriptionParse().parse(input)
        
        XCTAssertEqual(description.0, "")
        XCTAssertEqual(description.1, 105553136666336)
        XCTAssertEqual(description.2, 176)
    }
    
    func testSymbolicated() throws {
        let input = "<LeakySwiftObject 0x600002424860> [32]"
        
        let description = try CycleObjectDescriptionParse().parse(input)
        
        XCTAssertEqual(description.0, "LeakySwiftObject")
        XCTAssertEqual(description.1, 105553154164832)
        XCTAssertEqual(description.2, 32)
    }
}

final class CyclePrefixParseTests: XCTestCase {
    func test() throws {
        let input = "4 (128 bytes)"
        let prefix = try CyclePrefixParse().parse(input)
        XCTAssertEqual(prefix.0, 4)
        XCTAssertEqual(prefix.1, 128)
    }
}

final class CycleItemSymbolicatedParseTests: XCTestCase {
    func test() throws {
        let input = "ROOT CYCLE: <LeakySwiftObject 0x600002431220>"
        let item = try CycleItemSymbolicatedParse().parse(input)
        XCTAssertEqual(item.0, "ROOT CYCLE:")
        XCTAssertEqual(item.1, "LeakySwiftObject")
        XCTAssertEqual(item.2, 105553154216480)
    }
}

final class CycleItemUnsymbolicatedParseTests: XCTestCase {
    func test() throws {
        let input = "ROOT CYCLE: 0x7ff29c304630"
        let item = try CycleItemUnsymbolicatedParse().parse(input)
        XCTAssertEqual(item.0, "ROOT CYCLE:")
        XCTAssertNil(item.1)
        XCTAssertEqual(item.2, 140679979222576)
    }
    
    func testUnnamedCycleStep() throws {
        let input = "0x7ff29c305230"
        let item = try CycleItemUnsymbolicatedParse().parse(input)
        XCTAssertNil(item.0)
        XCTAssertNil(item.1)
        XCTAssertEqual(item.2, 0x7ff29c305230)
    }
}

final class CycleParseTests: XCTestCase {
    func testSymbolicated() throws {
        let input = """
                2 (64 bytes) ROOT CYCLE: <LeakySwiftObject 0x600002431220> [32]
                   1 (32 bytes) cycle --> ROOT CYCLE: <LeakySwiftObject 0x600002431240> [32]
                      cycle --> CYCLE BACK TO <LeakySwiftObject 0x600002431220> [32]
            """

        let cycle = try CycleParse().parse(input)
        
        XCTAssertEqual(cycle.count, 3)
        XCTAssertEqual(cycle[0].1.0.0, "ROOT CYCLE:")
        XCTAssertEqual(cycle[1].1.0.0, "cycle --> ROOT CYCLE:")
    }
    
    func testUnsymbolicated() throws {
        let input = """
                    4 (272 bytes) ROOT CYCLE: 0x7ff29c304500 [16]
                       3 (256 bytes) ROOT CYCLE: 0x7ff29c304630 [80]
                          CYCLE BACK TO 0x7ff29c304500 [16]
                          2 (176 bytes) 0x7ff29c305230 [144]
                             1 (32 bytes) 0x7ff29c304510 [32]
            """
        
        let cycle = try CycleParse().parse(input)
        
        XCTAssertEqual(cycle.count, 5)
        XCTAssertEqual(cycle.last?.1.0.2, 0x7ff29c304510)
    }
    
    func testDontParseSeparatorSymbolicated() {
        let input = """
                ----
            ROOT CYCLE: <LeakySwiftObject 0x600002431220>
            """
        
        XCTAssertThrowsError(try CycleParse().parse(input))
    }

    func testDontParseSeparatorUnsymbolicated() {
        let input = """
                ----
            ROOT CYCLE: 0x7ff29c304630 [80]
            """
        
        XCTAssertThrowsError(try CycleParse().parse(input))
    }
}

class SingleLeakParseTests: XCTestCase {
    func test() throws {
        let input = """
                      2 (64 bytes) ROOT CYCLE: <LeakySwiftObject 0x600002424860> [32]
                         1 (32 bytes) cycle --> ROOT CYCLE: <LeakySwiftObject 0x600002424880> [32]
                            cycle --> CYCLE BACK TO <LeakySwiftObject 0x600002424860> [32]
            """
        
        let leak = try SingleLeakParse().parse(input)
        
        print(leak)
    }
}


class MultiLeakParseTests: XCTestCase {
    func test() throws {
        let input = """
                4 (128 bytes) << TOTAL >>
                  ----
                  2 (64 bytes) ROOT CYCLE: <LeakySwiftObject 0x600002424860> [32]
                     1 (32 bytes) cycle --> ROOT CYCLE: <LeakySwiftObject 0x600002424880> [32]
                        cycle --> CYCLE BACK TO <LeakySwiftObject 0x600002424860> [32]
                  ----
                  2 (64 bytes) ROOT CYCLE: <LeakySwiftObject 0x6000024250e0> [32]
                     1 (32 bytes) cycle --> ROOT CYCLE: <LeakySwiftObject 0x600002425120> [32]
                        cycle --> CYCLE BACK TO <LeakySwiftObject 0x6000024250e0> [32]
            """
        
        
        let cycles = try MultiLeakParse().parse(input)
        XCTAssertEqual(cycles.0.0, 4)
        XCTAssertEqual(cycles.0.1, 128)
        XCTAssertEqual(cycles.1.count, 2)
    }
}
