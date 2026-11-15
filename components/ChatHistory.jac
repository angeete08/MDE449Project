import from ..services.chat { get_chat_history, delete_chat_history }

def:pub ChatHistory() -> JsxElement {
    has history: dict[str, any] = {}, error: str = "", busy: bool = False;
    async can with entry {
        try { history = await get_chat_history(); } except Exception { error = "Could not load chat history. Reopen History to retry."; }
    }
    async def clear() {
        if not window.confirm("Delete this week's Stride Coach chat history from your account?") { return; }
        busy = True;
        try { await delete_chat_history(); history = await get_chat_history(); error = ""; }
        except Exception { error = "Could not delete chat history. Try again."; }
        finally { busy = False; }
    }
    return <section className="chat-history"><h3>This week's Stride Coach conversations</h3>
        <p>{"Week of " + str(history.get("week", "")) + " · Monday–Sunday, America/Detroit. Earlier weeks are deleted on your next account visit. Up to 100 exchanges; photos are not saved."}</p>
        {error and <p role="alert">{error}</p>}
        {len(history.get("turns", [])) == 0 and <p>No saved conversations this week. Ask a question in Coach to start.</p>}
        {for turn in history.get("turns", []) {
            <details key={turn["id"]}><summary>{turn["question"]}</summary><time>{turn["created_at"]}</time><p className="whitespace-pre-wrap">{turn["answer"]}</p></details>
        }}
        <button type="button" disabled={busy or len(history.get("turns", [])) == 0} onClick={clear}>Delete this week's chat history</button>
    </section>;
}
