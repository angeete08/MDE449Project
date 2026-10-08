"""Stride full-stack Jac entry point."""
import from planner { create_plan, submit_feedback, restore_plan }
import ".global.css";
import from .frontend { FitnessApp }

def:pub app -> JsxElement {
    <FitnessApp/>
}
