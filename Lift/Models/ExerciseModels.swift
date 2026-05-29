import Foundation
import SwiftData

@Model
public class Exercise {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var muscleGroupString: String
    public var equipmentString: String
    public var trackingTypeString: String
    public var isCustom: Bool
    public var isFavorite: Bool
    
    public var muscleGroup: MuscleGroup {
        get { MuscleGroup(rawValue: muscleGroupString) ?? .chest }
        set { muscleGroupString = newValue.rawValue }
    }
    
    public var equipment: EquipmentType {
        get { EquipmentType(rawValue: equipmentString) ?? .other }
        set { equipmentString = newValue.rawValue }
    }
    
    public var trackingType: TrackingType {
        get { TrackingType(rawValue: trackingTypeString) ?? .weightReps }
        set { trackingTypeString = newValue.rawValue }
    }
    
    public init(id: UUID = UUID(), name: String, muscleGroup: MuscleGroup, equipment: EquipmentType, trackingType: TrackingType = .weightReps, isCustom: Bool = false, isFavorite: Bool = false) {
        self.id = id
        self.name = name
        self.muscleGroupString = muscleGroup.rawValue
        self.equipmentString = equipment.rawValue
        self.trackingTypeString = trackingType.rawValue
        self.isCustom = isCustom
        self.isFavorite = isFavorite
    }
}
