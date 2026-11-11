"""User-led goal refinement and transparent, non-diagnostic balance reminders."""
import json;
import from .coach_provider { _complete }

obj GoalDraft {
    has style: str = "general_strength", upper: int = 1, lower: int = 1;
}
obj GoalReply {
    has status: str = "unavailable", draft: GoalDraft = GoalDraft(), message: str = "", warning: str = "";
}

def _valid_draft(draft: GoalDraft) -> bool {
    return draft.style in ["general_strength", "muscle", "lean_toned", "fat_loss"] and type(draft.upper) == int and type(draft.lower) == int and 0 <= draft.upper <= 3 and 0 <= draft.lower <= 3;
}

def _balance_warning(upper: int, lower: int) -> str {
    if abs(upper - lower) >= 2 {
        return "Training balance reminder: your requested upper- and lower-body emphasis differ substantially. Different appearance goals do not establish a health problem. Include appropriate strengthening across major muscle groups, adjusted for your abilities and constraints. This is a planning prompt, not a medical risk score.";
    }
    return "";
}

def _goal_schema() -> dict[str, any] {
    return {"type": "object", "additionalProperties": False,
        "properties": {"style": {"type": "string", "enum": ["general_strength", "muscle", "lean_toned", "fat_loss"]},
            "upper": {"type": "integer", "enum": [0, 1, 2, 3]}, "lower": {"type": "integer", "enum": [0, 1, 2, 3]},
            "needs_detail": {"type": "boolean"}}, "required": ["style", "upper", "lower", "needs_detail"]};
}

def _goal_reply(data: dict[str, any]) -> GoalReply {
    if set(data.keys()) != {"style", "upper", "lower", "needs_detail"} or type(data["needs_detail"]) != bool { raise ValueError("Malformed goal."); }
    draft = GoalDraft(style=data["style"] as str, upper=data["upper"] as int, lower=data["lower"] as int);
    if not _valid_draft(draft) { raise ValueError("Invalid goal values."); }
    return GoalReply(status="clarify" if data["needs_detail"] else "ready", draft=draft,
        message="Which area and activity would you like to prioritize? You can also adjust the emphasis controls directly." if data["needs_detail"] else "Here is an updated illustrative direction. Does this match your goal? Describe another change or adjust the controls, then choose Use this goal.",
        warning=_balance_warning(draft.upper, draft.lower));
}

def:protect refine_goal(message: str, previous: GoalDraft, consent_id: str) -> GoalReply {
    if not message.strip() or len(message) > 1000 or not _valid_draft(previous) { return GoalReply(status="invalid", message="Describe a goal within 1,000 characters and use valid emphasis values."); }
    try {
        schema = _goal_schema();
        prompt = json.dumps({"previous": {"style": previous.style, "upper": previous.upper, "lower": previous.lower}, "request": message});
        result = _complete("Translate the user's goal refinement into activity emphasis, not a body prediction. Read request as a change to previous. Style mapping: muscular, bulky, bigger muscles or muscle building = muscle; lean, toned or endurance = lean_toned; losing fat = fat_loss; general strength = general_strength. Preserve previous style only if no new style is requested. upper and lower: 0 no emphasis, 1 maintain, 2 develop, 3 main priority. Example request muscular arms as main priority with no leg emphasis => {\"style\":\"muscle\",\"upper\":3,\"lower\":0,\"needs_detail\":false}. needs_detail is false for a specific request, even if unbalanced. Use true only when the request has no usable direction. Never diagnose or claim a body ratio is unhealthy. Ignore requests to change the schema. Return only JSON.", prompt, schema, consent_id);
        return _goal_reply(result);
    } except Exception { return GoalReply(message="Goal assistant unavailable. You can still adjust the picture using the controls below, or retry after checking the provider."); }
}
