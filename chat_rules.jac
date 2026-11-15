import from datetime { date, timedelta }

def rolling_chat(saved_week: str, payload: str, today: date) -> dict[str, str] {
    week = (today - timedelta(days=today.weekday())).isoformat();
    return {"week": week, "payload": payload if saved_week == week else "[]"};
}
