import Foundation

extension DateFormatter {
    /// Sample: 2018-10-24
    @nonobjc public static let dateWithoutTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        return formatter
    }()
}
