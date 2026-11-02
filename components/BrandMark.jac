def:pub BrandMark(compact: bool = False) -> JsxElement {
    <img
        src="/static/assets/stride-logo.png"
        alt="Stride logo"
        className={"stride-brand-mark " + ("stride-brand-mark-compact" if compact else "")}
    />
}
