import from ..services.stride { ask_coach, coach_available }
import from .ui.button { Button }
import from .ui.input { Input }

def:pub ChatCoach() -> JsxElement {
    has messages: list[dict[str, str]] = [
            {
                "role": "assistant",
                "content": "Hi! Ask me about your Stride plan or general fitness."
            }
        ],
        draft: str = "",
        error: str = "",
        sending: bool = False,
        configured: bool = True;

    async can with entry {
        try {
            configured = await coach_available();
        } except Exception {
            configured = True;
        }
    }

    async def send_message() {
        question = draft.strip();
        if sending or not question {
            return;
        }

        previous = messages[-12:];
        pending = [*messages, {"role": "user", "content": question}];
        messages = pending;
        draft = "";
        error = "";
        sending = True;
        try {
            answer = await ask_coach(question, previous);
            messages = [*pending, {"role": "assistant", "content": answer}];
        } except Exception {
            error = "Stride Coach could not get a reply from Gemini. Try again in a minute; if it keeps failing, check the API key, quota and internet connection.";
        } finally {
            sending = False;
        }
    }

    return
        <section className="flex flex-col gap-4">
            <div>
                <h2 className="text-xl font-semibold">Stride Coach</h2>
                <p className="text-sm text-muted-foreground">
                    General fitness guidance and answers about using Stride.
                </p>
            </div>
            <div
                className="flex max-h-[28rem] flex-col gap-3 overflow-y-auto rounded-lg border bg-background p-4"
                role="log"
                aria-live="polite"
                aria-label="Coach conversation"
            >
                {for (i, message) in enumerate(messages) {
                    <div
                        key={str(i)}
                        className={"max-w-[85%] whitespace-pre-wrap rounded-lg px-3 py-2 text-sm "
                            + (
                                "self-end bg-primary text-primary-foreground"
                                    if message["role"] == "user"
                                    else "self-start bg-muted"
                            )}
                    >
                        <p className="mb-1 text-xs font-medium">
                            {"You" if message["role"] == "user" else "Stride Coach"}
                        </p>
                        <p>{message["content"]}</p>
                    </div>
                }}
                {sending and <p className="text-sm text-muted-foreground" role="status">
                    Stride Coach is thinking…
                </p>}
            </div>
            {not configured and <p className="text-sm text-destructive" role="alert">
                Stride Coach is not set up on this server. Add GOOGLE_API_KEY to the project .env file and restart jac run.
            </p>}
            {error and <p className="text-sm text-destructive" role="alert">{error}</p>}
            <div className="flex gap-2">
                <Input
                    value={draft}
                    maxLength="1200"
                    aria-label="Ask Stride Coach"
                    placeholder="Ask about your plan or fitness…"
                    disabled={sending or not configured}
                    onChange={lambda (e: ChangeEvent) { draft = e.target.value; }}
                />
                <Button
                    disabled={sending or not configured or not draft.strip()}
                    onClick={send_message}
                >
                    Send
                </Button>
            </div>
            <p className="text-xs text-muted-foreground">
                Responses use Google Gemini and may be inaccurate. Your question, recent chat history, and limited fitness preferences are sent to Google; health notes and health summaries are not. Stride does not save this conversation to your account. Avoid sharing sensitive or medical information. This is general information, not medical advice.
            </p>
        </section>;
}
