"""One calendar week of account-private Coach turns. No photos are stored here."""
import json;
import from uuid { UUID }
import from datetime { datetime, timezone }
import from services.stride { require_profile, ask_coach, MUTATION_LOCK }

def:priv get_chat_history() -> dict[str, any] {
    with MUTATION_LOCK {
        p = require_profile();
        return {"week": p.chat_week, "turns": json.loads(p.chat_json)};
    }
}

def:priv delete_chat_history() -> bool {
    with MUTATION_LOCK {
        require_profile().chat_json = "[]";
        return True;
    }
}

def:priv send_saved_coach(question: str, request_id: str) -> dict[str, any] {
    if not isinstance(question, str) or not question.strip() or len(question) > 1200 {
        raise ValueError("Enter a question of 1–1200 characters.");
    }
    if str(UUID(request_id)) != request_id { raise ValueError("Invalid chat request."); }
    with MUTATION_LOCK {
        p = require_profile();
        turns = json.loads(p.chat_json);
        for turn in turns {
            if turn["id"] == request_id {
                if turn["question"] != question.strip() { raise ValueError("Request already used."); }
                return {"week": p.chat_week, "turns": turns};
            }
        }
        if len(turns) >= 100 { raise ValueError("This week's chat is full. Delete its history to start again."); }
        conversation: list[dict[str, str]] = [];
        for turn in turns[-6:] {
            conversation.extend([{"role": "user", "content": turn["question"]}, {"role": "assistant", "content": turn["answer"]}]);
        }
        answer = ask_coach(question.strip(), conversation);
        turns.append({"id": request_id, "question": question.strip(), "answer": answer,
            "created_at": datetime.now(timezone.utc).isoformat()});
        p.chat_json = json.dumps(turns);
        return {"week": p.chat_week, "turns": turns};
    }
}
