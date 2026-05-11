import Foundation

enum ProgramSeed {
    static let nutritionTargets = NutritionTargets(calories: 1600, proteinGrams: 145, fatGrams: 50, carbsGrams: 145, waterOunces: 100)

    static let weeklySchedule: [WorkoutDay] = [
        WorkoutDay(id: .sunday, name: "Rest day + meal prep", focus: "Rest", subtitle: "Full rest. Sunday meal prep day.", isRestDay: true, exercises: []),
        WorkoutDay(id: .monday, name: "Lower A", focus: "Glute + Quad", subtitle: "Compound glute-builder, then quad-dominant work.", isRestDay: false, exercises: [
            exercise("barbell-hip-thrust", "Barbell Hip Thrust", 4, "8-10", "90-120s", "Top set is the heaviest."),
            exercise("heel-elevated-goblet-squat", "Heel-Elevated Goblet Squat", 3, "10", "75-90s", "Plates under heels, deep range."),
            exercise("db-walking-lunge", "DB Walking Lunge", 3, "10/leg", "60-90s", "Long steps."),
            exercise("leg-extension-machine", "Leg Extension Machine", 3, "12", "60s", "Squeeze at top, slow lower."),
            exercise("standing-calf-raise", "Standing Calf Raise", 3, "15", "45-60s", "Full stretch at the bottom.")
        ]),
        WorkoutDay(id: .tuesday, name: "Upper Push", focus: "Chest, shoulders, triceps", subtitle: "Chest, shoulders, triceps.", isRestDay: false, exercises: [
            exercise("db-bench-press", "DB Bench Press", 3, "8-10", "90s", "Control the lowering."),
            exercise("seated-db-shoulder-press", "Seated DB Shoulder Press", 3, "8-10", "90s", "Bench at 80-85 degrees."),
            exercise("cable-lateral-raise", "Cable Lateral Raise", 3, "12", "45-60s", "Lead with the elbow."),
            exercise("incline-db-press", "Incline DB Press", 3, "10", "90s", "30 degrees, not steeper."),
            exercise("triceps-rope-pushdown", "Triceps Rope Pushdown", 3, "12", "45-60s", "Elbows pinned to ribs."),
            exercise("plank", "Plank", 3, "30-45 seconds", "60s", "Glutes squeezed.")
        ]),
        WorkoutDay(id: .wednesday, name: "Lower B", focus: "Glute + Hamstring", subtitle: "Posterior chain emphasis.", isRestDay: false, exercises: [
            exercise("barbell-romanian-deadlift", "Barbell Romanian Deadlift", 4, "8-10", "90-120s", "Hinge, do not squat."),
            exercise("cable-glute-kickback", "Cable Glute Kickback", 3, "12/leg", "45s", "Squeeze at the top."),
            exercise("db-bulgarian-split-squat", "DB Bulgarian Split Squat", 3, "8/leg", "60-90s", "Slight forward lean."),
            exercise("seated-hamstring-curl", "Seated Hamstring Curl", 3, "12", "60s", "Slow eccentric."),
            exercise("hip-abduction-machine", "Hip Abduction Machine", 3, "15", "45-60s", "Lean forward 15 degrees."),
            exercise("hanging-knee-raise", "Hanging Knee Raise", 3, "10-12", "60s", "Roll the hips up.")
        ]),
        WorkoutDay(id: .thursday, name: "Rest day", focus: "Rest", subtitle: "Full recovery. Optional 20-30 minute walk. No lifting.", isRestDay: true, exercises: []),
        WorkoutDay(id: .friday, name: "Upper Pull", focus: "Back, biceps, core", subtitle: "Back and biceps.", isRestDay: false, exercises: [
            exercise("lat-pulldown", "Lat Pulldown", 4, "10", "90s", "Elbows to ribs."),
            exercise("seated-cable-row", "Seated Cable Row", 3, "10", "90s", "Squeeze the shoulder blades."),
            exercise("db-single-arm-row", "DB Single-Arm Row", 3, "10/arm", "60s", "Do not twist the torso."),
            exercise("cable-face-pull", "Cable Face Pull", 3, "12-15", "45-60s", "Elbows up and out."),
            exercise("db-curl", "DB Curl", 3, "10", "60s", "Squeeze at the top."),
            exercise("pallof-press", "Pallof Press", 3, "10/side", "45s", "Resist the rotation.")
        ]),
        WorkoutDay(id: .saturday, name: "Lower C", focus: "Glute Volume Day", subtitle: "Highest-volume glute day of the week.", isRestDay: false, exercises: [
            exercise("smith-machine-hip-thrust", "Smith Machine Hip Thrust", 4, "12", "90s", "Push the weight."),
            exercise("db-sumo-deadlift", "DB Sumo Deadlift", 3, "8", "90s", "Drive knees out."),
            exercise("db-step-up", "DB Step-Up", 3, "10/leg", "60s", "Drive through the heel."),
            exercise("cable-pull-through", "Cable Pull-Through", 3, "12", "60-75s", "Squeeze the glutes hard at the top."),
            exercise("hip-abduction-machine-saturday", "Hip Abduction Machine", 3, "15 + drop set on last", "60s", "Drop set on last set.")
        ])
    ]

    static let mealTemplates: [MealTemplate] = [
        meal("protein-oatmeal", .breakfast, "Protein Oatmeal", "Oats, whey, peanut butter, banana, cinnamon.", 410, 31, 11, 48, [
            ingredient("rolled-oats", "Rolled oats", "1/2 cup", .pantry),
            ingredient("whey-protein", "Whey protein", "1 scoop", .supplementsExtras),
            ingredient("natural-peanut-butter", "Natural peanut butter", "1 tbsp", .pantry),
            ingredient("banana", "Banana", "1/2", .produce)
        ]),
        meal("greek-yogurt-power-bowl", .breakfast, "Greek Yogurt Power Bowl", "Greek yogurt, berries, honey, granola, chia.", 340, 28, 8, 42, [
            ingredient("greek-yogurt", "Non-fat Greek yogurt", "1 cup", .dairyEggs),
            ingredient("berries", "Mixed berries", "1/2 cup", .produce),
            ingredient("honey", "Honey", "1 tbsp", .pantry),
            ingredient("granola", "Granola", "2 tbsp", .pantry),
            ingredient("chia-seeds", "Chia seeds", "1 tbsp", .pantry)
        ]),
        meal("chicken-rice-power-bowl", .lunch, "Chicken & Rice Power Bowl", "Chicken breast, rice, broccoli, olive oil, lemon.", 470, 42, 14, 38, [
            ingredient("chicken-breast", "Boneless skinless chicken breast", "5 oz", .meatSeafood),
            ingredient("jasmine-rice", "Jasmine rice", "1/2 cup cooked", .pantry),
            ingredient("broccoli", "Broccoli", "1 cup", .produce),
            ingredient("olive-oil", "Olive oil", "1 tbsp", .pantry),
            ingredient("lemon", "Lemon", "1", .produce)
        ]),
        meal("sheet-pan-salmon-veg", .dinner, "Sheet-Pan Salmon & Veg", "Salmon, zucchini, bell peppers, sweet potato.", 470, 35, 22, 32, [
            ingredient("salmon", "Salmon fillet", "5 oz", .meatSeafood),
            ingredient("zucchini", "Zucchini", "1 cup", .produce),
            ingredient("bell-peppers", "Bell peppers", "1 cup", .produce),
            ingredient("sweet-potato", "Sweet potato", "1/2", .produce)
        ]),
        meal("protein-shake", .snack, "Protein Shake", "Whey with water or almond milk.", 120, 25, 1, 3, [
            ingredient("whey-protein", "Whey protein", "1 scoop", .supplementsExtras),
            ingredient("almond-milk", "Unsweetened almond milk", "1 cup", .dairyEggs)
        ])
    ]

    static func workout(for weekday: Weekday) -> WorkoutDay? {
        weeklySchedule.first { $0.id == weekday }
    }

    private static func exercise(_ id: String, _ name: String, _ sets: Int, _ reps: String, _ rest: String, _ cue: String) -> Exercise {
        Exercise(
            id: id,
            name: name,
            sets: sets,
            repRange: reps,
            rest: rest,
            cue: cue,
            formCues: [cue, "Brace your core.", "Control the lowering phase."],
            mistakes: ["Using momentum.", "Letting form break down."],
            feel: "Target muscles working without sharp pain.",
            demoURL: URL(string: "https://www.youtube.com/results?search_query=\(name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name)+proper+form")
        )
    }

    private static func meal(
        _ id: String,
        _ kind: MealKind,
        _ name: String,
        _ detail: String,
        _ calories: Int,
        _ protein: Int,
        _ fat: Int,
        _ carbs: Int,
        _ ingredients: [Ingredient]
    ) -> MealTemplate {
        MealTemplate(
            id: id,
            kind: kind,
            name: name,
            detail: detail,
            calories: calories,
            proteinGrams: protein,
            fatGrams: fat,
            carbsGrams: carbs,
            ingredients: ingredients
        )
    }

    private static func ingredient(_ id: String, _ name: String, _ quantity: String, _ category: GroceryCategory) -> Ingredient {
        Ingredient(id: id, name: name, quantity: quantity, category: category)
    }
}
