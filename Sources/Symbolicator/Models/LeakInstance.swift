import Foundation

enum LeakInstance {
    case cycle(LeakCycle)
    case root(LeakRoot)
}
