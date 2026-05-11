import Foundation

enum ProteinTracker {
    static func totalProtein(meals: [MealTemplate], quickAdds: [Int]) -> Int {
        meals.reduce(0) { $0 + $1.proteinGrams } + quickAdds.reduce(0, +)
    }

    static func progress(total: Int, target: Int) -> Double {
        guard target > 0 else { return 0 }
        return min(1, Double(total) / Double(target))
    }
}
