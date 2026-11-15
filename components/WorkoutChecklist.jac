import from ..workout_rules { exercise_kcal, exercise_minutes, exercise_met }

def:pub WorkoutChecklist(exercises: list[dict[str, any]], completed: list[int], locked: bool,
    onToggle: Callable[[int, bool], None], logged_kcal: int = 0) -> JsxElement {
    total = sum([exercise_kcal(e) for (i, e) in enumerate(exercises) if i in completed]);
    return <section className="workout-checklist" aria-label="Exercise completion">
        {for (i, e) in enumerate(exercises) {
            <div key={i} className="exercise-check-row">
                <label><input type="checkbox" checked={i in completed} disabled={locked}
                    onChange={lambda (event: any) { onToggle(i, event.target.checked); }}/>
                    <span><strong>{e["name"]}</strong><small>{str(e["duration"]) + " min" if e.get("duration") else str(e["sets"]) + " × " + str(e["reps"])}</small></span>
                </label>
                <span className="exercise-energy" title={str(exercise_minutes(e)) + " minute block · " + str(exercise_met(e)) + " MET · 70 kg reference"}>{"≈ " + str(exercise_kcal(e)) + " kcal"}<small>{str(exercise_minutes(e)) + " min estimate"}</small></span>
                <a href={"https://www.youtube.com/results?search_query=" + encodeURIComponent(e["name"] + " exercise tutorial")}
                    target="_blank" rel="noopener noreferrer" aria-label={"Tutorial for " + e["name"]}>Tutorial ↗</a>
            </div>
        }}
        <div className="completed-energy" role="status">
            <p>{"Estimated calories burned · checked exercises: " + str(total) + " kcal"}</p>
            <p>{"Logged activities: " + str(logged_kcal) + " kcal"}</p>
            <strong>{"Total: " + str(total + logged_kcal) + " kcal"}</strong>
        </div>
        {len(exercises) > 0 and <details className="estimate-explainer"><summary>How these estimates work</summary><p>Estimates use 2024 Adult Compendium activity categories for a 70 kg reference person: weighted squats/deadlifts 5 MET, other resistance 3.5, bodyweight 3, light core 2.8, moderate walking 3.8 and mobility 2.3. Timed exercises use scheduled minutes. Strength blocks assume 2.5 minutes per ten-rep set including rest/setup; that duration is an app assumption. Actual calories vary with weight, time and effort. Checking a box records completion, not a measurement. Log only additional activity so workouts are not counted twice.</p><a href="https://pacompendium.com/conditioning-exercise/" target="_blank" rel="noopener noreferrer">Resistance / core references ↗</a>{" · "}<a href="https://pacompendium.com/walking/" target="_blank" rel="noopener noreferrer">Walking reference ↗</a></details>}
    </section>;
}
