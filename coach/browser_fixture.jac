"""Run explicitly for browser QA; synthetic pixels only, never a user photo."""
import from PIL { Image, ImageDraw }

test "export synthetic browser fixtures" {
    picture = Image.new("RGB", (640, 480), "#dfe9d4");
    draw = ImageDraw.Draw(picture);
    draw.rectangle((30, 30, 280, 430), fill="#527b53");
    draw.ellipse((340, 100, 580, 340), fill="#c68b46");
    picture.save("/tmp/stride-coach-fixture.png");
    with open("/tmp/stride-coach-invalid.png", "w") as file { file.write("not an image"); }
    print("Synthetic browser fixtures written to /tmp/stride-coach-fixture.png and /tmp/stride-coach-invalid.png");
}
