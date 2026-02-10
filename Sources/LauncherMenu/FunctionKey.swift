import Foundation

enum FunctionKey: Int, CaseIterable, Codable {
    case f1 = 1
    case f2 = 2
    case f3 = 3
    case f4 = 4
    case f5 = 5
    case f6 = 6
    case f7 = 7
    case f8 = 8
    case f9 = 9
    case f10 = 10
    case f11 = 11
    case f12 = 12

    var label: String {
        "F\(rawValue)"
    }
}
