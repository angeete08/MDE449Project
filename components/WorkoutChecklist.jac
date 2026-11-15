import from ..workout_rules { exercise_kcal }

def:pub WorkoutChecklist(exercises: list[dict[str, any]], completed: list[int], locked: bool,
    onToggle: Callable[[int, bool], None]) -> JsxElement {
    total = sum([exercise_kcal(e) for (i, e) in enumerate(exercises) if i in completed]);
    return <section className="workout-checklist" aria-label="Exercise completion">
        {for (i, e) in enumerate(exercises) {
            <div key={i} className="exercise-check-row">
                <label><input type="checkbox" checked={i in completed} disabled={locked}
                    onChange={lambda (event: any) { onToggle(i, event.target.checked); }}/>
                    <span><strong>{e["name"]}</strong><small>{str(e["duration"]) + " min" if e.get("duration") else str(e["sets"]) + " × " + str(e["reps"])}</small></span>
                </label>
                <span className="exercise-energy">{"≈ " + str(exercise_kcal(e)) + " kcal"}</span>
                <a href={"https://www.youtube.com/results?search_query=" + encodeURIComponent(e["name"] + " exercise tutorial")}
                    target="_blank" rel="noopener noreferrer" aria-label={"Tutorial for " + e["name"]}>Tutorial ↗</a>
            </div>
        }}
        {len(exercises) > 0 and <p className="completed-energy" role="status">{"Estimated calories burned · checked exercises: " + str(total) + " kcal"}</p>}
        {len(exercises) > 0 and <details className="estimate-explainer"><summary>How these estimates work</summary><p>Illustrative estimates for a 70 kg person at a moderate pace. Timed exercises use scheduled minutes. Strength assumes 3 seconds per repetition plus 45 seconds between sets. Your actual energy use varies with weight, pace, rest and effort. Checking a box records completion, not a measurement.</p><a href="https://pacompendium.com/" target="_blank" rel="noopener noreferrer">2024 Adult Compendium MET references ↗</a></details>}
    </section>;
}
