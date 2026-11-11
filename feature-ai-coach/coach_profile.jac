"""Profile contract and authoritative validation. No existing app data is read."""
import from datetime { date }
import from zoneinfo { ZoneInfo }
import from coach_goals { _balance_warning }

obj CoachProfile {
    has goal: str = "general_strength",
        region: str = "full_body",
        experience: str = "beginner",
        equipment: list[str] = [],
        weekdays: list[int] = [0, 2, 4],
        minutes: int = 30,
        start_date: str = "",
        timezone: str = "UTC",
        constraints: str = "", activity_days: int = 0,
        custom_goal: str = "", custom_style: str = "general_strength",
        upper_emphasis: int = 1, lower_emphasis: int = 1;
}

obj ProfileResult {
    has valid: bool = False, errors: list[str] = [], warning: str = "", baseline: str = "";
}

def:pub validate_profile(profile: CoachProfile) -> ProfileResult {
    errors: list[str] = [];
    if profile.goal not in ["fat_loss", "lean_toned", "muscle", "general_strength", "other"] {
        errors.append("Choose a supported goal.");
    }
    if profile.region not in ["shoulders", "arms", "chest", "back", "core", "glutes", "legs", "full_body", "unknown"] {
        errors.append("Choose a supported focus region.");
    }
    if profile.experience not in ["beginner", "intermediate", "experienced"] {
        errors.append("Choose a supported experience level.");
    }
    if len(profile.equipment) > 4 or len(set(profile.equipment)) != len(profile.equipment) {
        errors.append("Equipment must be unique and supported.");
    }
    for item in profile.equipment {
        if item not in ["dumbbells", "bands", "gym", "mat"] { errors.append("Unsupported equipment."); }
    }
    if not profile.weekdays or len(profile.weekdays) > 7 or len(set(profile.weekdays)) != len(profile.weekdays) {
        errors.append("Choose at least one unique weekday.");
    }
    for day in profile.weekdays {
        if type(day) != int or day < 0 or day > 6 { errors.append("Weekdays must be integers from 0 to 6."); }
    }
    if type(profile.minutes) != int or profile.minutes < 10 or profile.minutes > 120 {
        errors.append("Session duration must be 10–120 whole minutes.");
    }
    try {
        parsed = date.fromisoformat(profile.start_date);
        if parsed.isoformat() != profile.start_date { errors.append("Use a YYYY-MM-DD start date."); }
    } except Exception { errors.append("Enter a valid start date."); }
    try { ZoneInfo(profile.timezone); }
    except Exception { errors.append("Choose a valid IANA timezone, such as America/Detroit."); }
    if len(profile.constraints) > 1000 { errors.append("Keep movement notes within 1,000 characters."); }
    if type(profile.activity_days) != int or profile.activity_days < 0 or profile.activity_days > 7 { errors.append("Activity days must be a whole number from 0 to 7."); }
    if profile.goal == "other" {
        if not profile.custom_goal.strip() or len(profile.custom_goal) > 1000 { errors.append("Open Customize goal and choose Use this goal."); }
        if profile.custom_style not in ["fat_loss", "lean_toned", "muscle", "general_strength"] { errors.append("Choose a supported custom activity direction."); }
    }
    if type(profile.upper_emphasis) != int or type(profile.lower_emphasis) != int or not 0 <= profile.upper_emphasis <= 3 or not 0 <= profile.lower_emphasis <= 3 { errors.append("Use emphasis values from 0 to 3."); }
    baseline = f"Your reported starting point: {profile.activity_days} active days per week; {profile.experience} experience. This is self-reported activity, not a measured fitness or body-composition score.";
    warning = _balance_warning(profile.upper_emphasis, profile.lower_emphasis) if not errors and profile.goal == "other" else "";
    return ProfileResult(valid=not errors, errors=errors, warning=warning, baseline=baseline if not errors else "");
}
