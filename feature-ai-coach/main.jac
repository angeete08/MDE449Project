import from coach_profile { CoachProfile, ProfileResult, validate_profile }
import from coach_media { PhotoResult, prepare_photo }
import from coach_provider { ProviderInfo, provider_info }
import from coach_vision { PhotoObservation, analyze_photo }
import from coach_goals { GoalDraft, GoalReply, refine_goal }
import from .coach_ui { Coach }
import ".styles.css";

def:pub app() -> JsxElement { <Coach /> }
