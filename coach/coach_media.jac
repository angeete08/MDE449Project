"""Ephemeral media boundary: decode, validate, orient, strip metadata, return.
No filesystem, graph, logs, public URL, external provider, or persistent store.
Only normalized bytes cross back to the browser's in-memory preview.
"""
import base64;
import warnings;
import from io { BytesIO }
import from PIL { Image, ImageOps }

obj PhotoResult {
    has valid: bool = False, error: str = "", data_url: str = "",
        width: int = 0, height: int = 0, mime: str = "image/jpeg";
}

def:protect prepare_photo(data_url: str) -> PhotoResult {
    if len(data_url) > 13981100 { return PhotoResult(error="Image must be at most 10 MB."); }
    try {
        pieces = data_url.split(",", 1);
        if len(pieces) != 2 { return PhotoResult(error="Choose a JPEG, PNG or WebP image."); }
        allowed = {"data:image/jpeg;base64": "JPEG", "data:image/png;base64": "PNG", "data:image/webp;base64": "WEBP"};
        if pieces[0] not in allowed { return PhotoResult(error="Choose a JPEG, PNG or WebP image."); }
        raw = base64.b64decode(pieces[1], validate=True);
        if len(raw) > 10485760 { return PhotoResult(error="Image must be at most 10 MB."); }
        with warnings.catch_warnings() {
            warnings.simplefilter("error", Image.DecompressionBombWarning);
            with Image.open(BytesIO(raw)) as source {
                if source.format != allowed[pieces[0]] { return PhotoResult(error="Image bytes do not match the declared format."); }
                w = source.width;
                h = source.height;
                if w < 32 or h < 32 or w > 8192 or h > 8192 or w * h > 16000000 {
                    return PhotoResult(error="Use an image at least 32 px per side, at most 8192 px per side and 16 megapixels.");
                }
                if getattr(source, "n_frames", 1) != 1 { return PhotoResult(error="Choose a still image, not an animation."); }
                source.verify();
            }
            with Image.open(BytesIO(raw)) as source {
                oriented = ImageOps.exif_transpose(source);
                oriented.thumbnail((1600, 1600));
                rgba = oriented.convert("RGBA");
                clean = Image.new("RGB", rgba.size, "white");
                clean.paste(rgba, mask=rgba.getchannel("A"));
                out = BytesIO();
                clean.save(out, format="JPEG", quality=90);
                return PhotoResult(valid=True, data_url="data:image/jpeg;base64," + base64.b64encode(out.getvalue()).decode("ascii"), width=clean.width, height=clean.height);
            }
        }
    } except Exception {
        return PhotoResult(error="This image could not be decoded. Try another JPEG, PNG or WebP.");
    }
}
