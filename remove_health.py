from pathlib import Path

path = Path("components/DashboardApp.jac")
source = path.read_text()
original = source


def remove(text):
    global source
    if text not in source:
        raise ValueError(f"Expected code not found: {text[:80]}")
    source = source.replace(text, "", 1)


remove(
    '                        <TabsTrigger value="health">Health</TabsTrigger>\n'
)

start = source.index('                    <TabsContent value="health"')
end = source.index('                    <TabsContent value="history"', start)
source = source[:start] + source[end:]

for text in [
    "import from ..health_panel { AppleHealthSync }\n",
    "import from .ManualAverages { ManualAverages }\n",
    "    save_health_summary,\n",
    "    get_health_summary,\n",
    "        health: dict[str, any] = {},\n",
    "                get_health_summary(),\n",
    "            health = results[4];\n",
]:
    remove(text)

source = source.replace(
    "            meals = results[5];",
    "            meals = results[4];",
    1,
)

start = source.index("    async def imported(summary: dict[str, any]) {")
end = source.index("    async def break_suggestion()", start)
source = source[:start] + source[end:]

path.write_text(source)
print("Removed Health tab and associated dashboard logic.")
