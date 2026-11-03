import Foundation

enum WeightUnit: String, Codable, CaseIterable, Hashable, Identifiable {
    case lb
    case kg

    static let poundsPerKilogram = 2.20462

    var id: String { rawValue }
    var symbol: String { rawValue }

    func convert(_ value: Double, to target: WeightUnit) -> Double {
        guard self != target else { return value }
        switch self {
        case .kg:
            return value * Self.poundsPerKilogram
        case .lb:
            return value / Self.poundsPerKilogram
        }
    }
}

enum WeightFormatter {
    /// Rounds to one decimal and drops a trailing ".0".
    static func string(_ value: Double) -> String {
        let rounded = (value * 10).rounded() / 10
        if rounded.rounded() == rounded {
            return String(Int(rounded))
        }
        return String(format: "%.1f", rounded)
    }
}

extension SetEntry {
    /// Entries logged before units existed were always pounds.
    var weightUnit: WeightUnit { unit ?? .lb }

    var repsValue: Int? {
        Int(repsText.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    func weight(in target: WeightUnit) -> Double? {
        guard let value = Double(weightText.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return nil
        }
        return weightUnit.convert(value, to: target)
    }

    /// Weight text shown in the target unit; converts only when the stored unit differs.
    func displayWeightText(in target: WeightUnit) -> String {
        guard weightUnit != target, let converted = weight(in: target) else {
            return weightText
        }
        return WeightFormatter.string(converted)
    }

    var hasLoggedValues: Bool {
        !weightText.trimmingCharacters(in: .whitespaces).isEmpty
            && !repsText.trimmingCharacters(in: .whitespaces).isEmpty
    }
}
