import Foundation

enum DemoLinkCatalog {
    static func url(for id: String, fallbackName: String) -> URL {
        if let slug = curatedSlugs[id] {
            return muscleWikiURL(slug)
        }
        if let slug = adaptiveSlug(for: id) {
            return muscleWikiURL(slug)
        }

        return muscleWikiURL(slug(for: fallbackName))
    }

    private static func muscleWikiURL(_ slug: String) -> URL {
        URL(string: "https://musclewiki.com/exercise/\(slug)")!
    }

    private static func slug(for name: String) -> String {
        name
            .lowercased()
            .replacingOccurrences(of: "+", with: " ")
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
    }

    private static func adaptiveSlug(for id: String) -> String? {
        if id.hasSuffix("-supported-split-squat") {
            return "split-squat"
        }
        if id.hasSuffix("-push-up-progression") {
            return "push-up"
        }
        if id.hasSuffix("-incline-push-up-practice") {
            return "incline-push-up"
        }
        if id.hasSuffix("-run-walk-intervals") {
            return "treadmill-running"
        }
        if id.hasSuffix("-walk-intervals") {
            return "treadmill-walking"
        }
        return nil
    }

    private static let curatedSlugs: [String: String] = [
        "assisted-pull-up-machine": "assisted-pull-up",
        "barbell-hip-thrust": "barbell-hip-thrust",
        "barbell-romanian-deadlift": "barbell-romanian-deadlift",
        "banded-glute-kickback": "glute-kickback",
        "cable-face-pull": "cable-face-pull",
        "cable-glute-kickback": "cable-glute-kickback",
        "cable-lateral-raise": "cable-lateral-raise",
        "cable-pull-through": "cable-pull-through",
        "cable-single-arm-row": "cable-single-arm-row",
        "chest-supported-row": "chest-supported-row",
        "db-bench-press": "dumbbell-bench-press",
        "db-bulgarian-split-squat": "dumbbell-bulgarian-split-squat",
        "db-curl": "dumbbell-curl",
        "db-hip-thrust": "dumbbell-hip-thrust",
        "db-lateral-raise": "dumbbell-lateral-raise",
        "db-reverse-lunge": "dumbbell-reverse-lunge",
        "db-single-arm-row": "dumbbell-single-arm-row",
        "db-step-up": "dumbbell-step-up",
        "db-sumo-deadlift": "dumbbell-sumo-deadlift",
        "db-walking-lunge": "dumbbell-walking-lunge",
        "heel-elevated-goblet-squat": "goblet-squat",
        "hip-abduction-machine": "machine-hip-abduction",
        "hip-abduction-machine-saturday": "machine-hip-abduction",
        "incline-db-press": "dumbbell-incline-bench-press",
        "kettlebell-sumo-deadlift": "kettlebell-sumo-deadlift",
        "lat-pulldown": "lat-pulldown",
        "leg-extension-machine": "leg-extension",
        "leg-press": "leg-press",
        "leg-press-single-leg": "single-leg-leg-press",
        "lying-hamstring-curl": "lying-leg-curl",
        "machine-chest-press": "machine-chest-press",
        "machine-glute-bridge": "glute-bridge",
        "machine-glute-kickback": "machine-glute-kickback",
        "machine-high-row": "machine-high-row",
        "machine-lateral-raise": "machine-lateral-raise",
        "machine-row": "machine-row",
        "machine-shoulder-press": "machine-shoulder-press",
        "pallof-press": "pallof-press",
        "plank": "plank",
        "push-up": "push-up",
        "reverse-lunge": "reverse-lunge",
        "seated-cable-row": "seated-cable-row",
        "seated-db-shoulder-press": "dumbbell-shoulder-press",
        "seated-hamstring-curl": "seated-leg-curl",
        "sissy-squat-assisted": "sissy-squat",
        "smith-machine-bench-press": "smith-machine-bench-press",
        "smith-machine-hip-thrust": "smith-machine-hip-thrust",
        "smith-machine-romanian-deadlift": "smith-machine-romanian-deadlift",
        "smith-machine-split-squat": "smith-machine-split-squat",
        "smith-machine-squat": "smith-machine-squat",
        "spanish-squat": "spanish-squat",
        "split-squat": "split-squat",
        "stability-ball-hamstring-curl": "stability-ball-hamstring-curl",
        "standing-calf-raise": "standing-calf-raise",
        "standing-landmine-press": "landmine-press",
        "straight-arm-pulldown": "straight-arm-pulldown",
        "triceps-rope-pushdown": "triceps-rope-pushdown",
        "wl-assisted-pull-up-machine": "assisted-pull-up",
        "wl-bike-easy": "stationary-bike",
        "wl-box-squat": "box-squat",
        "wl-box-squat-sub": "box-squat",
        "wl-cable-pull-through": "cable-pull-through",
        "wl-chest-supported-db-row": "chest-supported-dumbbell-row",
        "wl-chest-supported-row": "chest-supported-row",
        "wl-db-bench-press": "dumbbell-bench-press",
        "wl-db-bench-press-sub": "dumbbell-bench-press",
        "wl-db-romanian-deadlift": "dumbbell-romanian-deadlift",
        "wl-dead-bug": "dead-bug",
        "wl-elliptical-finisher": "elliptical",
        "wl-goblet-squat": "goblet-squat",
        "wl-goblet-squat-sub": "goblet-squat",
        "wl-hip-flexor-mobility": "hip-flexor-stretch",
        "wl-incline-push-up": "incline-push-up",
        "wl-incline-push-up-sub": "incline-push-up",
        "wl-incline-walk": "treadmill-walking",
        "wl-incline-walk-finisher": "treadmill-walking",
        "wl-lat-pulldown": "lat-pulldown",
        "wl-leg-press": "leg-press",
        "wl-leg-press-sub": "leg-press",
        "wl-long-walk": "treadmill-walking",
        "wl-machine-chest-press": "machine-chest-press",
        "wl-machine-chest-press-sub": "machine-chest-press",
        "wl-machine-row": "machine-row",
        "wl-machine-row-sub": "machine-row",
        "wl-pallof-press": "pallof-press",
        "wl-plank": "plank",
        "wl-reverse-lunge": "reverse-lunge",
        "wl-seated-cable-row": "seated-cable-row",
        "wl-seated-cable-row-sub": "seated-cable-row",
        "wl-side-plank": "side-plank",
        "wl-single-leg-leg-press": "single-leg-leg-press",
        "wl-smith-machine-rdl": "smith-machine-romanian-deadlift",
        "wl-smith-machine-squat": "smith-machine-squat",
        "wl-step-up": "dumbbell-step-up",
        "wl-straight-arm-pulldown": "straight-arm-pulldown"
    ]
}
