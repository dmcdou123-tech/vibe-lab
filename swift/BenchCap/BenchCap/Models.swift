import Foundation
import SwiftData

// Core subject identity
@Model
final class Subject {
    @Attribute(.unique) var id: UUID
    var name: String
    var species: String
    var protocolNumber: String

    @Relationship(deleteRule: .cascade, inverse: \InstrumentInstance.subject)
    var instruments: [InstrumentInstance]

    init(name: String, species: String, protocolNumber: String) {
        self.id = UUID()
        self.name = name
        self.species = species
        self.protocolNumber = protocolNumber
        self.instruments = []
    }
}

// Instrument definition (v0 only surgical log)
@Model
final class Instrument {
    @Attribute(.unique) var id: UUID
    var name: String
    var instrumentType: InstrumentType

    init(name: String, instrumentType: InstrumentType) {
        self.id = UUID()
        self.name = name
        self.instrumentType = instrumentType
    }
}

enum InstrumentType: String, Codable, CaseIterable, Identifiable {
    case surgicalLog

    var id: String { rawValue }
}

// Named time node within an instrument instance
@Model
final class TimeNode {
    @Attribute(.unique) var id: UUID
    var label: String
    var timestamp: Date?

    init(label: String, timestamp: Date? = nil) {
        self.id = UUID()
        self.label = label
        self.timestamp = timestamp
    }
}

// Field entry captures typed values and their capture time
@Model
final class FieldEntry {
    @Attribute(.unique) var id: UUID
    var fieldName: String
    var valueString: String
    var valueType: FieldValueType
    var capturedAt: Date

    init(fieldName: String, valueString: String, valueType: FieldValueType, capturedAt: Date = .now) {
        self.id = UUID()
        self.fieldName = fieldName
        self.valueString = valueString
        self.valueType = valueType
        self.capturedAt = capturedAt
    }
}

enum FieldValueType: String, Codable {
    case text
    case number
    case boolean
    case timestamp
}

enum CompletionState: String, Codable, CaseIterable, Identifiable {
    case incomplete
    case complete
    case completedWithDeviations

    var id: String { rawValue }

    var label: String {
        switch self {
        case .incomplete: return "Incomplete"
        case .complete: return "Complete"
        case .completedWithDeviations: return "Completed with deviations"
        }
    }
}

// Instance of an instrument tied to a subject and day
@Model
final class InstrumentInstance {
    @Attribute(.unique) var id: UUID
    var instrument: Instrument
    @Relationship var subject: Subject
    var recordCreatedAt: Date
    var surgeon: String
    var procedureType: String
    var analgesicRequired: Bool
    var analgesicDose: String
    var analgesicUnits: String
    var observations: String
    var deviations: String
    var surgeryDate: Date?
    var weightGrams: String
    var completionState: CompletionState

    // Time nodes
    var anesthesiaStart: Date?
    var surgeryStart: Date?
    var surgeryEnd: Date?
    var returnToCage: Date?
    var isofluraneStartTime: Date?
    var carprofenAdminTime: Date?
    var bupiLidoAdminTime: Date?
    var carprofenDoseML: String
    var bupiLidoDoseML: String

    // Field entries to preserve capture semantics
    var fieldEntries: [FieldEntry]
    var timeNodes: [TimeNode]
    @Relationship(deleteRule: .cascade, inverse: \CorrectionNote.instance)
    var corrections: [CorrectionNote]

    init(instrument: Instrument, subject: Subject, recordCreatedAt: Date = .now) {
        self.id = UUID()
        self.instrument = instrument
        self.subject = subject
        self.recordCreatedAt = recordCreatedAt
        self.surgeon = ""
        self.procedureType = ""
        self.analgesicRequired = false
        self.analgesicDose = ""
        self.analgesicUnits = ""
        self.observations = ""
        self.deviations = ""
        self.surgeryDate = nil
        self.weightGrams = ""
        self.completionState = .incomplete
        self.anesthesiaStart = nil
        self.surgeryStart = nil
        self.surgeryEnd = nil
        self.returnToCage = nil
        self.isofluraneStartTime = nil
        self.carprofenAdminTime = nil
        self.bupiLidoAdminTime = nil
        self.carprofenDoseML = ""
        self.bupiLidoDoseML = ""
        self.fieldEntries = []
        self.timeNodes = []
        self.corrections = []
    }
}

extension InstrumentInstance {
    var surgeryDurationMinutes: Int? {
        guard let start = surgeryStart, let end = surgeryEnd, end > start else { return nil }
        return Int(end.timeIntervalSince(start) / 60)
    }

    var recoveryDurationMinutes: Int? {
        guard let end = surgeryEnd, let back = returnToCage, back > end else { return nil }
        return Int(back.timeIntervalSince(end) / 60)
    }

    var dayKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: recordCreatedAt)
    }
}

@Model
final class CorrectionNote {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var text: String
    var authorInitials: String?
    @Relationship var instance: InstrumentInstance

    init(text: String, authorInitials: String? = nil, instance: InstrumentInstance, createdAt: Date = .now) {
        self.id = UUID()
        self.createdAt = createdAt
        self.text = text
        self.authorInitials = authorInitials
        self.instance = instance
    }
}
