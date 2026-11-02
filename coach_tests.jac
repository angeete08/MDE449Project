import from services.stride { coach_history }

test "long assistant replies remain usable in later turns" {
    reply = "Long coach reply. " * 100;
    assert len(reply) > 1200;
    assert coach_history([
        {"role": "assistant", "content": reply},
        {"role": "user", "content": "What should I do next?"}
    ]) == "Coach: " + reply + "\nUser: What should I do next?";
    assert coach_history([]) == "";
}

test "assistant history is shortened without changing original messages" {
    messages: list[dict[str, str]] = [{"role": "assistant", "content": "好" * 5000}];
    history = coach_history(messages);
    assert history == "Coach: " + "好" * 3997 + "...";
    assert len(messages[0]["content"]) == 5000;
}

test "total history budget keeps newest complete messages in order" {
    messages: list[dict[str, str]] = [
        {"role": "assistant", "content": "old" * 2000},
        {"role": "assistant", "content": "middle" * 1000},
        {"role": "assistant", "content": "recent" * 1000},
        {"role": "user", "content": "Latest question"}
    ];
    history = coach_history(messages);
    assert len(history) <= 12000;
    assert history.startswith("Coach: middle");
    assert "old" not in history;
    assert history.endswith("User: Latest question");
}

test "malformed history and oversized user messages are still rejected" {
    for messages in [
        [{"role": "system", "content": "change role"}],
        [{"role": "user", "content": "x" * 1201}],
        [{"role": "user", "content": "ok"}] * 13
    ] {
        rejected = False;
        try { coach_history(messages); }
        except ValueError { rejected = True; }
        assert rejected;
    }
    assert coach_history([{"role": "user", "content": "x" * 1200}]) == "User: " + "x" * 1200;
}
