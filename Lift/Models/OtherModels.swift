import Foundation
import SwiftData

@Model
public class BodyweightEntry {
    @Attribute(.unique) public var id: UUID
    public var date: Date
    public var weight: Double
    
    public init(id: UUID = UUID(), date: Date = Date(), weight: Double) {
        self.id = id
        self.date = date
        self.weight = weight
    }
}

@Model
public class PersonalRecord {
    @Attribute(.unique) public var id: UUID
    public var exerciseName: String
    public var typeString: String // weight, reps, volume, oneRepMax
    public var value: Double
    public var weight: Double
    public var reps: Int
    public var estimatedOneRepMax: Double
    public var date: Date
    public var workoutId: UUID?
    
    public init(id: UUID = UUID(), exerciseName: String, typeString: String, value: Double, weight: Double, reps: Int, estimatedOneRepMax: Double, date: Date = Date(), workoutId: UUID? = nil) {
        self.id = id
        self.exerciseName = exerciseName
        self.typeString = typeString
        self.value = value
        self.weight = weight
        self.reps = reps
        self.estimatedOneRepMax = estimatedOneRepMax
        self.date = date
        self.workoutId = workoutId
    }
}

@Model
public class Achievement {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var desc: String
    public var unlockedAt: Date
    public var badgeIcon: String
    
    public init(id: UUID = UUID(), title: String, desc: String, unlockedAt: Date = Date(), badgeIcon: String) {
        self.id = id
        self.title = title
        self.desc = desc
        self.unlockedAt = unlockedAt
        self.badgeIcon = badgeIcon
    }
}

// Struct for local usage or share card options
public struct ShareCard: Codable, Identifiable {
    public var id: UUID
    public var type: ShareCardType
    public var style: ShareCardStyle
    public var title: String
    public var subtitle: String
    public var stats: [String: String]
    public var createdAt: Date
    
    public init(id: UUID = UUID(), type: ShareCardType, style: ShareCardStyle, title: String, subtitle: String, stats: [String : String], createdAt: Date = Date()) {
        self.id = id
        self.type = type
        self.style = style
        self.title = title
        self.subtitle = subtitle
        self.stats = stats
        self.createdAt = createdAt
    }
}
