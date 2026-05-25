import Foundation

enum ProgramSeed {
    static let defaultProgramID = "lower-body-strength-recomp"

    static let programs: [TrainingProgram] = [
        strengthProgram,
        weightLossProgram
    ]

    static var defaultProgram: TrainingProgram {
        program(id: defaultProgramID) ?? strengthProgram
    }

    static func program(id: String) -> TrainingProgram? {
        programs.first { $0.id == id }
    }

    static var nutritionTargets: NutritionTargets {
        defaultProgram.nutritionTargets
    }

    static var quickProteinAnchors: [QuickProteinAnchor] {
        defaultProgram.quickProteinAnchors
    }

    static var weeklySchedule: [WorkoutDay] {
        defaultProgram.weeklySchedule
    }

    static var mealTemplates: [MealTemplate] {
        defaultProgram.mealTemplates
    }

    private static let strengthProgram = TrainingProgram(
        id: defaultProgramID,
        name: "Lower Body Strength + Recomp",
        goal: "Build muscle and burn fat",
        summary: "A lower-body-forward resistance plan for glutes, legs, upper-body balance, and high-protein recomposition.",
        weeklyStructure: [
            "3 lower-body strength days",
            "2 upper-body support days",
            "2 recovery and prep days"
        ],
        prepSteps: [
            "Cook proteins",
            "Prep carbs and produce",
            "Stage the week"
        ],
        nutritionTargets: strengthNutritionTargets,
        quickProteinAnchors: strengthQuickProteinAnchors,
        weeklySchedule: strengthWeeklySchedule,
        mealTemplates: strengthMealTemplates
    )

    private static let weightLossProgram = TrainingProgram(
        id: "weight-loss-foundation",
        name: "Weight Loss Foundation",
        goal: "Weight loss",
        summary: "A sustainable fat-loss plan with full-body strength, low-impact conditioning, core work, mobility, and simple high-protein meals.",
        weeklyStructure: [
            "3 full-body strength days",
            "2 low-impact conditioning days",
            "1 mobility and core day",
            "1 rest and prep day"
        ],
        prepSteps: [
            "Pick lean protein anchors for four meals",
            "Prep grab-and-go produce",
            "Stage walking shoes, water, and quick protein"
        ],
        nutritionTargets: NutritionTargets(calories: 1450, proteinGrams: 135, fatGrams: 45, carbsGrams: 125, waterOunces: 100),
        quickProteinAnchors: [
            QuickProteinAnchor(id: "whey", label: "Whey", proteinGrams: 25),
            QuickProteinAnchor(id: "greek-yogurt", label: "Greek yogurt", proteinGrams: 20),
            QuickProteinAnchor(id: "turkey", label: "Turkey", proteinGrams: 28),
            QuickProteinAnchor(id: "eggs", label: "Eggs", proteinGrams: 12),
            QuickProteinAnchor(id: "cottage-cheese", label: "Cottage cheese", proteinGrams: 24)
        ],
        weeklySchedule: [
            WorkoutDay(id: .sunday, name: "Rest + prep", focus: "Recovery", subtitle: "Full rest, grocery reset, and light walking if desired.", isRestDay: true, exercises: []),
            WorkoutDay(id: .monday, name: "Full Body A", focus: "Strength + conditioning", subtitle: "Big movements, steady pace, short finisher.", isRestDay: false, exercises: [
                exercise("wl-goblet-squat", "Goblet Squat", 3, "10-12", "60s", "Stay tall and control the lower."),
                exercise("wl-db-bench-press", "DB Bench Press", 3, "10", "60-75s", "Smooth reps, stop before form breaks."),
                exercise("wl-seated-cable-row", "Seated Cable Row", 3, "12", "60s", "Pull elbows to ribs."),
                exercise("wl-incline-walk-finisher", "Incline Walk Finisher", 1, "12 minutes", "Easy pace", "Use a pace you can sustain while breathing hard.")
            ]),
            WorkoutDay(id: .tuesday, name: "Zone 2 Walk", focus: "Conditioning", subtitle: "Low-impact cardio for calorie burn and recovery.", isRestDay: false, exercises: [
                exercise("wl-incline-walk", "Incline Treadmill Walk", 1, "30-40 minutes", "Steady", "Nasal breathing if possible, no running required."),
                exercise("wl-dead-bug", "Dead Bug", 3, "8/side", "45s", "Keep low back down.")
            ]),
            WorkoutDay(id: .wednesday, name: "Full Body B", focus: "Strength + core", subtitle: "Hinge, press, pull, and core stability.", isRestDay: false, exercises: [
                exercise("wl-db-romanian-deadlift", "DB Romanian Deadlift", 3, "10", "75s", "Push hips back and keep weights close."),
                exercise("wl-lat-pulldown", "Lat Pulldown", 3, "10-12", "60s", "Drive elbows down."),
                exercise("wl-step-up", "DB Step-Up", 3, "8/leg", "60s", "Drive through the full foot."),
                exercise("wl-pallof-press", "Pallof Press", 3, "10/side", "45s", "Resist rotation.")
            ]),
            WorkoutDay(id: .thursday, name: "Mobility + Core", focus: "Mobility", subtitle: "Move, recover, and keep the habit alive.", isRestDay: false, exercises: [
                exercise("wl-bike-easy", "Easy Bike", 1, "15-20 minutes", "Steady", "Keep this conversational."),
                exercise("wl-hip-flexor-mobility", "Hip Flexor Mobility", 2, "45 seconds/side", "30s", "Squeeze the back glute."),
                exercise("wl-side-plank", "Side Plank", 3, "20-30 seconds/side", "45s", "Keep ribs stacked.")
            ]),
            WorkoutDay(id: .friday, name: "Full Body C", focus: "Strength + conditioning", subtitle: "Moderate strength work and a machine cardio finish.", isRestDay: false, exercises: [
                exercise("wl-leg-press", "Leg Press", 3, "12", "60-75s", "Controlled reps, knees tracking."),
                exercise("wl-machine-chest-press", "Machine Chest Press", 3, "10-12", "60s", "Control the return."),
                exercise("wl-machine-row", "Machine Row", 3, "12", "60s", "Pause with shoulder blades squeezed."),
                exercise("wl-elliptical-finisher", "Elliptical Finisher", 1, "10-15 minutes", "Easy pace", "Keep moving without sprinting.")
            ]),
            WorkoutDay(id: .saturday, name: "Long Walk + Core", focus: "Conditioning", subtitle: "Long easy movement and light core work.", isRestDay: false, exercises: [
                exercise("wl-long-walk", "Outdoor or Treadmill Walk", 1, "40-60 minutes", "Steady", "Stay relaxed and keep the pace repeatable."),
                exercise("wl-plank", "Plank", 3, "30-45 seconds", "45s", "Squeeze glutes and breathe.")
            ])
        ],
        mealTemplates: [
            meal("egg-white-breakfast-wrap", .breakfast, "Egg White Breakfast Wrap", "Egg whites, whole egg, spinach, salsa, high-fiber tortilla.", 320, 32, 9, 30, [
                ingredient("egg-whites", "Egg whites", "3/4 cup", .dairyEggs),
                ingredient("eggs", "Egg", "1", .dairyEggs),
                ingredient("spinach", "Spinach", "1 cup", .produce),
                ingredient("salsa", "Salsa", "2 tbsp", .pantry),
                ingredient("high-fiber-tortilla", "High-fiber tortilla", "1", .pantry)
            ]),
            meal("turkey-lettuce-bowl", .lunch, "Turkey Lettuce Bowl", "Lean turkey, lettuce, cucumber, tomatoes, rice, Greek yogurt dressing.", 390, 40, 11, 34, [
                ingredient("lean-ground-turkey", "Lean ground turkey", "5 oz", .meatSeafood),
                ingredient("romaine", "Romaine lettuce", "2 cups", .produce),
                ingredient("cucumber", "Cucumber", "1/2", .produce),
                ingredient("tomatoes", "Cherry tomatoes", "1/2 cup", .produce),
                ingredient("brown-rice", "Brown rice", "1/3 cup cooked", .pantry),
                ingredient("greek-yogurt", "Non-fat Greek yogurt", "1/4 cup", .dairyEggs)
            ]),
            meal("chicken-veggie-skillet", .dinner, "Chicken Veggie Skillet", "Chicken breast, zucchini, peppers, cauliflower rice, avocado.", 430, 43, 16, 28, [
                ingredient("chicken-breast", "Boneless skinless chicken breast", "5 oz", .meatSeafood),
                ingredient("zucchini", "Zucchini", "1 cup", .produce),
                ingredient("bell-peppers", "Bell peppers", "1 cup", .produce),
                ingredient("cauliflower-rice", "Cauliflower rice", "1 cup", .produce),
                ingredient("avocado", "Avocado", "1/4", .produce)
            ]),
            meal("cottage-cheese-berries", .snack, "Cottage Cheese + Berries", "Cottage cheese, berries, cinnamon.", 220, 24, 4, 22, [
                ingredient("cottage-cheese", "Low-fat cottage cheese", "1 cup", .dairyEggs),
                ingredient("berries", "Mixed berries", "1/2 cup", .produce),
                ingredient("cinnamon", "Cinnamon", "1 tsp", .pantry)
            ]),
            meal("protein-shake", .snack, "Protein Shake", "Whey with water or almond milk.", 120, 25, 1, 3, [
                ingredient("whey-protein", "Whey protein", "1 scoop", .supplementsExtras),
                ingredient("almond-milk", "Unsweetened almond milk", "1 cup", .dairyEggs)
            ])
        ]
    )

    private static let strengthNutritionTargets = NutritionTargets(calories: 1600, proteinGrams: 145, fatGrams: 50, carbsGrams: 145, waterOunces: 100)

    private static let strengthQuickProteinAnchors: [QuickProteinAnchor] = [
        QuickProteinAnchor(id: "whey", label: "Whey", proteinGrams: 25),
        QuickProteinAnchor(id: "greek-yogurt", label: "Greek yogurt", proteinGrams: 20),
        QuickProteinAnchor(id: "chicken", label: "Chicken", proteinGrams: 30),
        QuickProteinAnchor(id: "eggs", label: "Eggs", proteinGrams: 12),
        QuickProteinAnchor(id: "tuna", label: "Tuna", proteinGrams: 25)
    ]

    private static let strengthWeeklySchedule: [WorkoutDay] = [
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

    private static let strengthMealTemplates: [MealTemplate] = [
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
            demoURL: URL(string: "https://www.youtube.com/results?search_query=\(name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name)+proper+form"),
            substitutions: substitutions(for: id)
        )
    }

    private static func substitutions(for exerciseID: String) -> [ExerciseSubstitution] {
        switch exerciseID {
        case "barbell-hip-thrust":
            return [
                substitution("smith-machine-hip-thrust", "Smith Machine Hip Thrust", "Smith machine", "Glutes", "Set the bar over the hips and lock out with a hard glute squeeze."),
                substitution("machine-glute-bridge", "Machine Glute Bridge", "Glute bridge machine", "Glutes", "Keep ribs down and pause at the top."),
                substitution("db-hip-thrust", "DB Hip Thrust", "Dumbbell + bench", "Glutes", "Hold the dumbbell steady and drive through the heels.")
            ]
        case "heel-elevated-goblet-squat":
            return [
                substitution("leg-press", "Leg Press", "Leg press", "Quads", "Place feet lower on the platform and keep the range controlled."),
                substitution("smith-machine-squat", "Smith Machine Squat", "Smith machine", "Quads", "Use a narrow stance and keep knees tracking over toes.")
            ]
        case "db-walking-lunge":
            return [
                substitution("db-reverse-lunge", "DB Reverse Lunge", "Dumbbells", "Glutes and quads", "Step back and keep the front foot planted."),
                substitution("split-squat", "Split Squat", "Dumbbells", "Glutes and quads", "Stay tall and move straight down.")
            ]
        case "leg-extension-machine":
            return [
                substitution("spanish-squat", "Spanish Squat", "Band", "Quads", "Sit back against the band and keep the torso tall."),
                substitution("sissy-squat-assisted", "Assisted Sissy Squat", "Rack or rail", "Quads", "Use support and keep tension in the quads.")
            ]
        case "db-bench-press":
            return [
                substitution("machine-chest-press", "Machine Chest Press", "Chest press machine", "Chest", "Set handles mid-chest and control the return."),
                substitution("push-up", "Push-Up", "Bodyweight", "Chest", "Keep ribs down and stop a rep before form breaks."),
                substitution("smith-machine-bench-press", "Smith Machine Bench Press", "Smith machine", "Chest", "Set the bench so the bar tracks over mid-chest.")
            ]
        case "seated-db-shoulder-press":
            return [
                substitution("machine-shoulder-press", "Machine Shoulder Press", "Shoulder press machine", "Shoulders", "Keep elbows slightly in front of the body."),
                substitution("standing-landmine-press", "Standing Landmine Press", "Landmine", "Shoulders", "Press up and forward without leaning back.")
            ]
        case "cable-lateral-raise":
            return [
                substitution("db-lateral-raise", "DB Lateral Raise", "Dumbbells", "Side delts", "Lead with elbows and stop around shoulder height."),
                substitution("machine-lateral-raise", "Machine Lateral Raise", "Lateral raise machine", "Side delts", "Keep shoulders down and move smoothly.")
            ]
        case "barbell-romanian-deadlift":
            return [
                substitution("db-romanian-deadlift", "DB Romanian Deadlift", "Dumbbells", "Hamstrings and glutes", "Push hips back and keep the weights close."),
                substitution("smith-machine-romanian-deadlift", "Smith Machine Romanian Deadlift", "Smith machine", "Hamstrings and glutes", "Use a soft knee and stop when hamstrings stretch.")
            ]
        case "cable-glute-kickback":
            return [
                substitution("machine-glute-kickback", "Machine Glute Kickback", "Glute kickback machine", "Glutes", "Pause with the glute squeezed."),
                substitution("banded-glute-kickback", "Banded Glute Kickback", "Band", "Glutes", "Keep hips square and move slowly.")
            ]
        case "db-bulgarian-split-squat":
            return [
                substitution("smith-machine-split-squat", "Smith Machine Split Squat", "Smith machine", "Glutes and quads", "Set the front foot far enough to stay stable."),
                substitution("reverse-lunge", "Reverse Lunge", "Dumbbells", "Glutes and quads", "Step back and drive through the front heel.")
            ]
        case "seated-hamstring-curl":
            return [
                substitution("lying-hamstring-curl", "Lying Hamstring Curl", "Hamstring curl machine", "Hamstrings", "Keep hips down and control the lower."),
                substitution("stability-ball-hamstring-curl", "Stability Ball Hamstring Curl", "Stability ball", "Hamstrings", "Keep hips lifted through the curl.")
            ]
        case "lat-pulldown":
            return [
                substitution("assisted-pull-up-machine", "Assisted Pull-Up Machine", "Assisted pull-up machine", "Lats", "Pull elbows toward ribs and avoid shrugging."),
                substitution("straight-arm-pulldown", "Straight-Arm Pulldown", "Cable", "Lats", "Keep arms mostly straight and sweep toward thighs.")
            ]
        case "seated-cable-row":
            return [
                substitution("chest-supported-row", "Chest-Supported Row", "Machine or incline bench", "Upper back", "Drive elbows back and keep chest supported."),
                substitution("machine-row", "Machine Row", "Row machine", "Upper back", "Pause with shoulder blades squeezed.")
            ]
        case "db-single-arm-row":
            return [
                substitution("cable-single-arm-row", "Cable Single-Arm Row", "Cable", "Back", "Pull the elbow toward the hip."),
                substitution("machine-high-row", "Machine High Row", "High row machine", "Back", "Keep ribs down and pull through elbows.")
            ]
        case "smith-machine-hip-thrust":
            return [
                substitution("barbell-hip-thrust", "Barbell Hip Thrust", "Barbell + bench", "Glutes", "Pad the bar and lock out with control."),
                substitution("machine-glute-bridge", "Machine Glute Bridge", "Glute bridge machine", "Glutes", "Keep the top pause strict.")
            ]
        case "db-sumo-deadlift":
            return [
                substitution("kettlebell-sumo-deadlift", "Kettlebell Sumo Deadlift", "Kettlebell", "Glutes and hamstrings", "Drive knees out and stand tall."),
                substitution("cable-pull-through", "Cable Pull-Through", "Cable", "Glutes and hamstrings", "Hinge back and squeeze through the hips.")
            ]
        case "db-step-up":
            return [
                substitution("leg-press-single-leg", "Single-Leg Leg Press", "Leg press", "Glutes and quads", "Drive through one heel and avoid locking the knee."),
                substitution("db-reverse-lunge", "DB Reverse Lunge", "Dumbbells", "Glutes and quads", "Use the front leg to pull back up.")
            ]
        default:
            return []
        }
    }

    private static func substitution(_ id: String, _ name: String, _ equipment: String, _ target: String, _ cue: String) -> ExerciseSubstitution {
        ExerciseSubstitution(
            id: id,
            name: name,
            equipment: equipment,
            target: target,
            cue: cue,
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
