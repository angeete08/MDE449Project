"""Stride full-stack Jac entry point."""
import from planner { create_plan, submit_feedback, restore_plan, meal_video }
import from health_sync { start_health_sync, health_sync_status, finish_health_sync, receive_health_batch, receive_health_log, release_health_sync }
import ".global.css";
import ".frontend.css";
import from .frontend { FitnessApp }

def:pub app -> JsxElement {
    <FitnessApp/>
}
