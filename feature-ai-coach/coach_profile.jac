"""Profile contract and authoritative validation. No existing app data is read."""
import from datetime { date }
import from zoneinfo { ZoneInfo }

obj CoachProfile {
    has goal: str = "general_strength",
        region: str = "full_body",
        experience: str = "beginner",
        equipment: list[str] = [],
        weekdays: list[int] = [0, 2, 4],
        minutes: int = 30,
        start_date: str = "",
        timezone: str = "UTC",
        constraints: str = "";
}

obj ProfileResult {
    has valid: bool = False, errors: list[str] = [];
}

def:pub validate_profile(profile: CoachProfile) -> ProfileResult {
    errors: list[str] = [];
    if profile.goal not in ["fat_loss", "lean_toned", "muscle", "general_strength"] {
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
    return ProfileResult(valid=not errors, errors=errors);
}
