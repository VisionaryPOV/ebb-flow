import Foundation

final class TestDateHolder: @unchecked Sendable {
    var value: Date

    init(_ value: Date) {
        self.value = value
    }
}