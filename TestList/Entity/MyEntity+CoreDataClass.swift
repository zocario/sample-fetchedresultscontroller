import Foundation
import CoreData

@objc(MyEntity)
public class MyEntity: NSManagedObject {
    func populateDate() {
        let date = Date(timeIntervalSince1970: .random(in: 0...Date().timeIntervalSince1970))
        updatedAt = date
        updatedDay = DateFormatter.dateWithoutTime.string(from: date)
    }
}
