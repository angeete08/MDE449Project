import from coach_profile { CoachProfile, ProfileResult, validate_profile }
import from coach_media { PhotoResult, prepare_photo }
import from .coach_ui { Coach }
import ".styles.css";

def:pub app() -> JsxElement { <Coach /> }
