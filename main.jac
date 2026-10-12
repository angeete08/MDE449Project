"""Stride full-stack Jac entry point."""
import from planner { create_plan, submit_feedback, restore_plan, meal_video }
import from calorie_data { search_foods, calculate_food_calories }
import from recipe_calories { match_calories, resolve_match, suggest_ingredient, estimate_recipe }
import ".global.css";
import ".frontend.css";
import from .frontend { FitnessApp }

def:pub app -> JsxElement {
    <FitnessApp/>
}
