import XCTest
import class Foundation.Bundle
@testable import Symbolicator
import Parsing

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
