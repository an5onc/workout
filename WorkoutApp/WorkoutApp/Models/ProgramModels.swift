import Foundation

enum Weekday: String, CaseIterable, Identifiable, Codable {
    case sunday, monday, tuesday, wednesday, thursday, friday, saturday

    var id: String { rawValue }
}

enum MealKind: String, CaseIterable, Identifiable, Codable {
    case breakfast, lunch, dinner, snack, preWorkout, postWorkout

    var id: String { rawValue }
}

enum GroceryCategory: String, CaseIterable, Identifiable, Codable {
    case produce = "Produce"
    case meatSeafood = "Meat & Seafood"
    case dairyEggs = "Dairy & Eggs"
    case pantry = "Pantry"
    case supplementsExtras = "Supplements & Extras"
    case other = "Other"

    var id: String { rawValue }
}

struct NutritionTargets: Hashable, Codable {
    let calories: Int
    let proteinGrams: Int
    let fatGrams: Int
    let carbsGrams: Int
    let waterOunces: Int
}

struct QuickProteinAnchor: Identifiable, Hashable, Codable {
    let id: String
    let label: String
    let proteinGrams: Int
}

struct Exercise: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let sets: Int
    let repRange: String
    let rest: String
    let cue: String
    let formCues: [String]
    let mistakes: [String]
    let feel: String
    let demoURL: URL?
}

struct WorkoutDay: Identifiable, Hashable, Codable {
    let id: Weekday
    let name: String
    let focus: String
    let subtitle: String
    let isRestDay: Bool
    let exercises: [Exercise]
}

struct Ingredient: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let quantity: String
    let category: GroceryCategory
}

struct MealTemplate: Identifiable, Hashable, Codable {
    let id: String
    let kind: MealKind
    let name: String
    let detail: String
    let calories: Int
    let proteinGrams: Int
    let fatGrams: Int
    let carbsGrams: Int
    let ingredients: [Ingredient]
}
