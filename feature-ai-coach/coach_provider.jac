"""One bounded model transport for local testing and HTTPS Chat Completions APIs."""
import os;
import json;
import hashlib;
import from http { client }
import from urllib.parse { urlsplit }

obj ProviderInfo {
    has ready: bool = False, external: bool = False, destination: str = "",
        vision_model: str = "", text_model: str = "", consent_id: str = "", error: str = "";
}

def _config() -> dict[str, any] {
    provider = os.getenv("COACH_PROVIDER", "ollama");
    if provider == "ollama" {
        return {"provider": provider, "base": "http://127.0.0.1:11434", "key": "",
            "vision": os.getenv("COACH_VISION_MODEL", "gemma3:4b"),
            "text": os.getenv("COACH_TEXT_MODEL", "qwen3:1.7b")};
    }
    if provider != "openai" { raise ValueError("Unsupported provider configuration."); }
    base = os.getenv("COACH_API_BASE", "https://api.openai.com/v1").rstrip("/");
    parsed = urlsplit(base);
    if parsed.scheme != "https" or not parsed.hostname or parsed.username or parsed.password or parsed.query or parsed.fragment {
        raise ValueError("API base must be an HTTPS URL without credentials or query parameters.");
    }
    key = os.getenv("COACH_API_KEY", "");
    model = os.getenv("COACH_API_MODEL", "");
    if not key or not model { raise ValueError("Set COACH_API_KEY and COACH_API_MODEL on the server."); }
    return {"provider": provider, "base": base, "key": key, "vision": model, "text": model};
}

def _info(config: dict[str, any]) -> ProviderInfo {
    identity = str(config["provider"]) + "|" + str(config["base"]) + "|" + str(config["vision"]) + "|" + str(config["text"]);
    return ProviderInfo(ready=True, external=config["provider"] != "ollama",
        destination=str(urlsplit(str(config["base"])).netloc), vision_model=str(config["vision"]), text_model=str(config["text"]),
        consent_id=hashlib.sha256(identity.encode()).hexdigest());
}

def:pub provider_info() -> ProviderInfo {
    try { return _info(_config()); }
    except Exception { return ProviderInfo(error="Model provider is not configured. Check the server settings; manual goals remain available."); }
}

def _payload(config: dict[str, any], system: str, prompt: str, schema: dict[str, any], image: str = "") -> dict[str, any] {
    model = config["vision"] if image else config["text"];
    if config["provider"] == "ollama" {
        message: dict[str, any] = {"role": "user", "content": prompt};
        if image { message["images"] = [image.split(",", 1)[1]]; }
        return {"model": model, "stream": False, "think": False, "keep_alive": "60s",
            "format": schema, "options": {"temperature": 0, "num_ctx": 4096, "num_predict": 512},
            "messages": [{"role": "system", "content": system}, message]};
    }
    content: list[dict[str, any]] = [{"type": "text", "text": prompt}];
    if image { content.append({"type": "image_url", "image_url": {"url": image}}); }
    return {"model": model, "stream": False, "store": False, "max_completion_tokens": 1024,
        "messages": [{"role": "system", "content": system}, {"role": "user", "content": content}],
        "response_format": {"type": "json_schema", "json_schema": {"name": "coach_result", "strict": True, "schema": schema}}};
}

def _send(base: str, path: str, payload: dict[str, any], key: str = "") -> dict[str, any] {
    parsed = urlsplit(base);
    connection = client.HTTPSConnection(parsed.hostname, parsed.port, timeout=90) if parsed.scheme == "https" else client.HTTPConnection(parsed.hostname, parsed.port, timeout=90);
    headers = {"Content-Type": "application/json"};
    if key { headers["Authorization"] = "Bearer " + key; }
    try {
        connection.request("POST", parsed.path.rstrip("/") + path, body=json.dumps(payload).encode(), headers=headers);
        response = connection.getresponse();
        if response.status != 200 { raise ValueError("Provider rejected the request."); }
        body = response.read(1048577);
        if len(body) > 1048576 { raise ValueError("Provider response too large."); }
        data = json.loads(body);
        if not isinstance(data, dict) { raise ValueError("Malformed provider response."); }
        return data;
    } finally { connection.close(); }
}

def _decode(provider: str, response: dict[str, any]) -> dict[str, any] {
    content = "";
    if provider == "ollama" {
        if response.get("done") is not True or response.get("done_reason") == "length" { raise ValueError("Incomplete model response."); }
        content = response["message"]["content"];
    } else {
        choice = response["choices"][0];
        if choice.get("finish_reason") != "stop" or choice["message"].get("refusal") { raise ValueError("Incomplete or refused model response."); }
        content = choice["message"]["content"];
    }
    if not isinstance(content, str) or len(content) > 16000 { raise ValueError("Malformed model output."); }
    result = json.loads(content);
    if not isinstance(result, dict) { raise ValueError("Expected structured output."); }
    return result;
}

def _complete(system: str, prompt: str, schema: dict[str, any], consent_id: str, image: str = "") -> dict[str, any] {
    config = _config();
    info = _info(config);
    # Ties each submission to the destination/model disclosed by the UI.
    if consent_id != info.consent_id { raise ValueError("Provider changed. Review the destination again."); }
    if image and config["provider"] == "ollama" {
        capabilities = _send(str(config["base"]), "/api/show", {"model": config["vision"]});
        if "vision" not in capabilities.get("capabilities", []) { raise ValueError("Selected model cannot accept images."); }
    }
    path = "/api/chat" if config["provider"] == "ollama" else "/chat/completions";
    response = _send(str(config["base"]), path, _payload(config, system, prompt, schema, image), str(config["key"]));
    return _decode(str(config["provider"]), response);
}
