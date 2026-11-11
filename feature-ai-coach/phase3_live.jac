"""Explicit local smoke test. Not part of the offline test suite; synthetic image only."""
import time;
import from coach_provider { provider_info }
import from coach_goals { GoalDraft, refine_goal }
import from coach_vision { analyze_photo }
import base64;
import from io { BytesIO }
import from PIL { Image }

test "local goal refinement and unrelated image abstention" {
    info = provider_info();
    assert info.ready and not info.external;
    started = time.monotonic();
    goal = refine_goal("I want muscular arms as my main priority, with no leg training emphasis.", GoalDraft(), info.consent_id);
    print("Local goal:", goal.status, goal.draft.style, goal.draft.upper, goal.draft.lower, "seconds", time.monotonic() - started);
    assert goal.status == "ready" and goal.draft.style == "muscle" and goal.warning;
    started = time.monotonic();
    output = BytesIO();
    Image.new("RGB", (640, 480), "green").save(output, format="PNG");
    observation = analyze_photo("data:image/png;base64," + base64.b64encode(output.getvalue()).decode("ascii"), info.consent_id);
    print("Local synthetic image:", observation.status, observation.regions, "seconds", time.monotonic() - started);
    assert observation.status == "uncertain";
}
