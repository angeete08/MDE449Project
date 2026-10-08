"""Client-side, selectable-text PDF export of the current plan."""
import from "jspdf" { jsPDF }

def:pub build_plan_pdf(state: dict[str, any]) -> any {
    doc = new(jsPDF, {"unit": "pt", "format": "a4", "compress": True});
    profile = state["profile"];
    ink = "#183c35";
    muted = "#60716c";
    paper = "#f6f5ef";
    accent = "#d9f17c";
    goal = {"active": "Stay active", "muscle": "Gain muscle", "lose": "Lose weight"}[profile["goal"]];
    equipment = {"bodyweight": "Bodyweight", "dumbbells": "Dumbbells", "gym": "Full gym"}[profile["equipment"]];
    diet = {"none": "No restriction", "vegetarian": "Vegetarian", "keto": "Keto", "protein": "High protein"}[profile["diet"]];
    experience = {"beginner": "Beginner", "intermediate": "Intermediate", "advanced": "Advanced"}[profile["experience"]];
    ratings = {"easy": "Too easy", "right": "Just right", "hard": "Too hard"};

    def text(value: str, x: float, y: float, size: float = 10, bold: bool = False, color: str = "#183c35") -> None {
        doc.setFont("helvetica", "bold" if bold else "normal");
        doc.setFontSize(size);
        doc.setTextColor(color);
        doc.text(value, x, y);
    }

    def paragraph(value: str, x: float, y: float, width: float, size: float = 9) -> None {
        doc.setFont("helvetica", "normal");
        doc.setFontSize(size);
        doc.setTextColor(muted);
        doc.text(doc.splitTextToSize(value, width), x, y, {"lineHeightFactor": 1.45});
    }

    def box(x: float, y: float, width: float, height: float, color: str) -> None {
        doc.setFillColor(color);
        doc.roundedRect(x, y, width, height, 9, 9, "F");
    }

    def frame(page: int, title: str, subtitle: str) -> None {
        doc.setFillColor(paper);
        doc.rect(0, 0, 595.28, 841.89, "F");
        text("stride", 38, 48, 25, True);
        text("YOUR WEEK. YOUR PACE.", 373, 46, 9, True, muted);
        doc.setDrawColor("#dfe4dc");
        doc.line(38, 65, 557, 65);
        text(title, 38, 101, 27, True);
        text(subtitle, 38, 122, 10, False, muted);
        doc.line(38, 789, 557, 789);
        text("STRIDE / PERSONAL FITNESS PLAN", 38, 809, 8, True, muted);
        text(str(page) + " / 2", 530, 809, 8, False, muted);
    }

    doc.setProperties({"title": "Stride - Weekly Fitness Plan", "author": "Stride", "subject": "Your current workouts and meal suggestions"});
    frame(1, "A week with intention.", "Your routine at a glance, with space to recover.");
    for (i, item) in enumerate([[str(profile["days"]), "WORKOUT DAYS"], [str(profile["calories"]), "KCAL / DAY TARGET"], [str(len(Object.keys(state["feedback"]))), "WORKOUTS LOGGED"]]) {
        x = 38 + i * 177;
        box(x, 144, 165, 69, accent if i == 0 else "#e7eddf");
        text(item[0], x + 15, 174, 24, True);
        text(item[1], x + 15, 196, 8, True);
    }
    text(goal + "  /  " + experience + "  /  " + equipment, 38, 237, 11, True);
    text("01 / WEEKLY SCHEDULE", 38, 269, 9, True, muted);
    box(38, 280, 519, 28, ink);
    text("DAY", 51, 298, 8, True, "#ffffff");
    text("SESSION", 150, 298, 8, True, "#ffffff");
    text("STATUS / FEEDBACK", 403, 298, 8, True, "#ffffff");
    for (i, day) in enumerate(state["plan"]) {
        y = 308 + i * 27;
        if i % 2 == 0 { box(38, y, 519, 27, "#ffffff"); }
        rating = state["feedback"][str(day["index"])];
        label = "Rest day" if day["rest"] else ("Logged - " + ratings[rating] if rating else "Not logged");
        text(day["day"], 51, y + 18, 9, True);
        text(day["title"], 150, y + 18, 9);
        text(label, 403, y + 18, 8, False, muted);
    }
    text("02 / SIMPLE MEAL IDEAS", 38, 527, 9, True, muted);
    text(diet + " / Approximate calories per serving", 38, 547, 10);
    for (i, meal) in enumerate(state["meals"]) {
        x = 38 + i * 177;
        box(x, 562, 165, 151, "#ffffff");
        text("IDEA 0" + str(i + 1), x + 13, 583, 8, True, muted);
        doc.setFont("helvetica", "bold");
        doc.setFontSize(12);
        doc.setTextColor(ink);
        doc.text(doc.splitTextToSize(meal["name"], 139), x + 13, 607, {"lineHeightFactor": 1.15});
        paragraph(meal["detail"], x + 13, 645, 139, 8);
        text("Approx. " + str(meal["calories"]) + " kcal", x + 13, 700, 10, True);
    }
    paragraph("Meal ideas are not a complete daily menu and do not add up to your calorie target. Your calorie target is user-entered; Stride does not calculate calorie needs or a deficit.", 38, 737, 519, 9);

    doc.addPage();
    frame(2, "Your training, in detail.", "Current sets, reps and durations, including saved feedback adjustments.");
    workouts = [day for day in state["plan"] if not day["rest"]];
    for (i, day) in enumerate(workouts) {
        x = 38 + (i % 2) * 266;
        y = 144 + (i // 2) * 201;
        box(x, y, 253, 187, "#ffffff");
        text(day["day"].upper(), x + 14, y + 21, 9, True, muted);
        text(day["title"], x + 14, y + 43, 16, True);
        text("Warm up: 5 min of gentle movement", x + 14, y + 60, 8, False, muted);
        for (j, exercise) in enumerate(day["exercises"]) {
            ey = y + 84 + j * 20;
            text(exercise["name"], x + 14, ey, 8);
            amount = str(exercise["duration"]) + " min" if exercise["duration"] else str(exercise["sets"]) + " x " + str(exercise["reps"]);
            text(amount, x + 206, ey, 8, True);
            doc.setDrawColor("#edf0e8");
            doc.line(x + 14, ey + 6, x + 239, ey + 6);
        }
        rating = state["feedback"][str(day["index"])];
        text("Logged: " + ratings[rating] if rating else "Not logged yet", x + 14, y + 173, 9, True, muted);
    }
    paragraph("Move slowly and choose a comfortable resistance or pace. Workout examples are for demonstration. Pause exercise if it causes pain. Rest days: take the day off, with optional gentle stretching.", 38, 756, 519, 8);
    return doc;
}

def:pub download_plan_pdf(state: dict[str, any]) -> None {
    doc = build_plan_pdf(state);
    doc.save("stride-weekly-plan.pdf");
}
