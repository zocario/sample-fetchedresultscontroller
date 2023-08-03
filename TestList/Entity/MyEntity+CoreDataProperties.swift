import Foundation
import CoreData


extension MyEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<MyEntity> {
        return NSFetchRequest<MyEntity>(entityName: "MyEntity")
    }

    @NSManaged public var updatedAt: Date
    @NSManaged public var updatedDay: String
    @NSManaged public var identifier: UUID
}

extension MyEntity : Identifiable {

}
