import from ..coach.coach_ui { Coach }
import from ..services.stride { ask_coach, coach_available }
import from ..services.chat { get_chat_history, send_saved_coach }
import from .ui.button { Button }
import from .ui.input { Input }

def chat_messages(history: dict[str, any]) -> list[dict[str, str]] {
    result: list[dict[str, str]] = [];
    for turn in history.get("turns", []) {
        result = [*result, {"role": "user", "content": turn["question"]}, {"role": "assistant", "content": turn["answer"]}];
    }
    return result;
}

def:pub ChatCoach(onPlanSaved: Callable[[], any] | None = None) -> JsxElement {
    has messages: list[dict[str, str]] = [
            {
                "role": "assistant",
                "content": "Hi! Ask me about your Stride plan or general fitness."
            }
        ],
        draft: str = "",
        error: str = "",
        sending: bool = False,
        configured: bool = True, request_id: str = "", retry_question: str = "", loaded: bool = False;

    async can with entry {
        try {
            configured = await coach_available();
            messages = chat_messages(await get_chat_history());
            loaded = True;
        } except Exception {
            error = "Could not load saved chat. Reopen Coach before sending.";
        }
    }

    async def send_message() {
        question = draft.strip();
        if sending or not question {
            return;
        }

        if not loaded { return; }
        if not request_id or retry_question != question {
            browser: any = window;
            request_id = str(browser.crypto.randomUUID());
            retry_question = question;
        }
        error = "";
        sending = True;
        try {
            messages = chat_messages(await send_saved_coach(question, request_id));
            draft = "";
            request_id = "";
            retry_question = "";
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
                    disabled={sending or not configured or not loaded}
                    onChange={lambda (e: ChangeEvent) { draft = e.target.value; }}
                />
                <Button
                    disabled={sending or not configured or not loaded or not draft.strip()}
                    onClick={send_message}
                >
                    Send
                </Button>
            </div>
            <p className="text-xs text-muted-foreground">
                Chat uses Google Gemini and requires internet. Your question, recent conversation and limited fitness preferences are sent to Google; injury notes are excluded. Conversations are saved to your account for the current Monday–Sunday week (America/Detroit), visible and deletable in History. Earlier weeks are deleted on your next account visit. Photos are not included. Responses may be inaccurate; avoid sensitive information. The separate Photo and goal studio uses its own displayed provider.
            </p>
            <Coach onSaved={onPlanSaved}/>
        </section>;
}
