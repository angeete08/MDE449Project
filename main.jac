"""Stride full-stack Jac entry point."""
import from planner { create_plan, submit_feedback, restore_plan, meal_video }
import ".global.css";
import ".frontend.css";
import from .frontend { FitnessApp }

def:pub app -> JsxElement {
    <FitnessApp/>
}
