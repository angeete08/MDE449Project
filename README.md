# Stride calorie calculator

This folder is the isolated Stride calorie calculator app, including its source, datasets, tests, and supporting fitness UI. The repository root and `MDE449Project-dev/` are separate applications. Run all calculator commands from this folder; do not run a feature entry or evaluation script through the root project's `jac run`.

Use Jac **0.37.21**, as pinned in `jac.toml`. From this folder:

```sh
cd /Users/zeta/Documents/MDE449Project/feature-calorie-calculator
jac install
jac run
```

The calculator uses port 8300. For browser verification, use `jac run --dev --port 8300 --api-port 8301`; these explicit ports fail if occupied. Runtime files live in this folder's `.jac/`. Never use `--takeover` to stop another app, or a broad `pkill` command.

Verify from this folder:

```sh
jac check .
jac test --jobs 0 planner_tests.jac calorie_tests.jac recipe_tests.jac web_nutrition_tests.jac nutrition_agent_tests.jac local_calories_tests.jac
```

`main.jac` registers the app and calorie endpoints. `frontend.jac` places `feature-calorie-calculator.jac` below meal advice. `calorie_data.jac` reads `data/foundation_foods_2025-12-18.json`; `recipe_calories.jac` provides automatic lookup and ingredient estimates. `frontend.css` and `global.css` provide the styling. `planner_tests.jac`, `calorie_tests.jac`, and `recipe_tests.jac` cover the existing app and this feature.

Enter a food or recipe name and click **Find calories**. The best name match appears immediately; alternative matches are collapsed under **Not the right match?** There is no required selection screen. Typos and word-order changes are supported, but generic names remain ambiguous: review the displayed preparation and variety.

Food calories equal kcal per 100 g × grams / 100, rounded to one decimal. The lookup prefers Atwater specific energy (2048), then general energy (2047), then legacy energy (1008), using only kcal entries. The 365-food USDA snapshot does not cover every ingredient or branded product. Missing energy data is never treated as zero. See [USDA's Foundation Foods documentation](https://fdc.nal.usda.gov/Foundation_Foods_Documentation/) for the nutrient basis.

TheMealDB supplies recipe quantities, not calorie labels. Ingredient rows start collapsed, with editable gram weights based on the listed quantities. Mass units convert directly. When web search cannot supply a weight, cups (240 ml), tablespoons (15 ml), teaspoons (5 ml), and common item counts use labeled kitchen approximations. Density defaults to 1 g/ml with ingredient-specific assumptions for flour, sugar, oil, butter, salt, rice, and oats. These are app assumptions, not measured recipe weights. Unsupported quantities stay blank if neither web lookup nor a local conversion resolves them. Recipe scale defaults to 1× and multiplies all entered weights; servings divides the scaled batch calories. Review the quantities and sources behind an automatic estimate. If neither Google nor USDA supplies calories, a package-label value is needed. Cooking losses, absorption, and cooked yield are not modeled. Exact base-name USDA equivalents can also provide a separately labeled recipe approximation.

## Default local Qwen estimate

The default calculator mode asks `qwen3:1.7b` running in Ollama for a rough kcal-per-100-g estimate of the food or dish name. It does not perform Google searches, USDA matching, or ingredient analysis in local mode. Jac validates the response format and numeric bounds, then multiplies the estimated energy by the portion weight (default 100 g). These checks do not establish nutritional correctness. Preparation and assumptions are displayed. This is not a nutrition-trained model; estimates have no retrieved source and may be substantially wrong. The previous evidence/ingredient workflow remains selectable.

With the final prompt, the development spot check returned estimates for eight real foods and rejected a nonsense name. Hummus was 320 kcal/100 g versus 229 in the bundled USDA record. The prompt supplies oil, sugar, and banana reference values to reduce serving-unit confusion; results for these foods are not independent accuracy evidence. Other results still contain errors and inaccurate assumptions. See `data/local_model_qwen3-1.7b_spot_check.json` for the actual outputs. Earlier Qwen2.5 0.5B/1.5B and Qwen3.5 0.8B attempts failed coverage or had severe calorie errors. The two Qwen2.5 models were removed; permission to remove Qwen3.5 0.8B was declined, so it remains installed but is not selected by default.

Install Ollama from its official distribution (or `brew install ollama`), then run:

```sh
ollama serve
```

In another terminal:

```sh
ollama pull qwen3:1.7b
cd /Users/zeta/Documents/MDE449Project/feature-calorie-calculator
jac run
```

The server calls only `http://127.0.0.1:11434/api/generate`. No API key is needed. `STRIDE_LOCAL_MODEL` can select another already-installed Ollama model. Successful kcal-per-100-g results are cached for an hour; changing portion grams scales the cached value. Invalid replies, unfamiliar foods, and an unavailable model return a clear error instead of a fabricated total.

## Jac nutrition agent

`nutrition_agent.jac` adds a byLLM agent for ingredients that web/local lookup cannot fully resolve, plus foods with no name match. It can search the bundled USDA records, query the broader USDA FoodData Central API with simpler or alternate names, and retrieve household portion gram weights. This is runtime retrieval-augmented generation (RAG), not a fine-tuned nutrition model. At most four unresolved ingredients per recipe are sent to the agent. Each agent allows three retrieval calls and four reasoning iterations.

The agent selects a retrieved food ID and proposes grams with an explicit assumption. Server code rejects invented IDs, invalid weights, and unsourced calorie values, preserves explicit recipe mass, and computes calories itself. Quantities such as oil for frying can use an explicitly labeled agent assumption; this is not measured absorption or recipe nutrition. Sources, assumptions, and preparation caveats stay visible in the expanded ingredient. Unresolved cases still remain manual. Source-ID validation establishes provenance, not that the selected food or assumed amount is correct.

Run `jac install` to install the byLLM dependencies. Before `jac run`, set `BYLLM_DEFAULT_MODEL` to a model supported by your provider and set that provider's API key in the terminal. See `jac guide jac-by-llm` for provider model names and key variables. Optionally set `USDA_API_KEY` for the broader food database and portion tools; without it, retrieval uses the bundled USDA data. Keep all keys outside source control. `SERPAPI_API_KEY` remains optional for the preceding Google lookup. Restart Jac after changing model/key settings.

Without a configured model, the agent is skipped and the existing lookup still works. Tests use MockLLM and mocked USDA HTTP responses; no live-model accuracy or calorie accuracy has been established.

## Fitted name model

`name_model.jac` implements a word and character 3/4-gram TF-IDF retrieval model in Jac. `train_matcher.jac` fits inverse document frequency weights and normalized document vectors using **790 TheMealDB recipe titles and 365 USDA food names**. The fitted artifact is bundled at `data/name_matcher.json` (1,155 titles, 9,314 learned term weights). Name normalization, token-coverage checks, exact-name preference, and modifier penalties rerank candidates. Similarity scores are not probabilities. This is an unsupervised name-retrieval model, **not a neural model or a trained calorie predictor**; there are no recipe calorie labels to train such a predictor.

Google lookup through [SerpAPI](https://serpapi.com/search-api) is the default source for food and ingredient calories and non-mass ingredient quantities, when a server-side key is configured. The local model still identifies recipes and alternative foods. Google values take priority over USDA matches and kitchen weight assumptions; explicit recipe mass is preserved. Local data and kitchen conversions fill gaps when a web lookup is unavailable or inconclusive. Searches run with six concurrent workers for the first 15 ingredients (up to 30 queries per recipe); remaining ingredients use local defaults. The server caches results for one hour and limits requests to 30 per minute per process. Search snippets must explicitly match the food and units; conflicting or unclear results are not filled. Every filled online value includes its source and is labeled an estimate. Manual overrides remain available. “To taste” and unspecified amounts remain unresolved rather than guessed. Online calorie records expire after an hour; reload the recipe to use them again. No API key is sent to the browser. Ingredient names and recipe quantities are sent to SerpAPI for Google searching.

The only required initial input is a food or recipe name. Food portions default to 100 g and recipes to one complete batch at 1× scale. These controls and ingredient edits start collapsed. Complete recipe totals calculate on load and recalculate when scale/servings change or an ingredient input loses focus. Unresolved values are identified before a total is shown; missing ingredients are never counted as zero. Manual input is only necessary to resolve unavailable values or override a default.

To enable lookup, set `SERPAPI_API_KEY` in the terminal that starts Jac (keep the key out of source control):

```sh
read -s "SERPAPI_API_KEY?SerpAPI key: "
export SERPAPI_API_KEY
jac run
```

Without a key or if the service fails, the app keeps working with local matches and manual inputs. Search results are snippets, not verified measurements of your recipe. Automated tests mock the search service; live lookup still needs verification with a configured key. Refresh and retrain the local corpus explicitly from this folder:

```sh
jac run --no-serve refresh_recipes.jac
jac run --no-serve train_matcher.jac
jac run --no-serve evaluate_matcher.jac
```

Restart `jac run` after refreshing or training to clear in-memory model/data caches. Refreshing uses 26 documented first-letter requests to [TheMealDB V1 API](https://www.themealdb.com/api.php), with the public educational test key `1`; it writes a new snapshot only after every request succeeds. The snapshot keeps only IDs, names, ingredient names, and measures. The API's terms for public app-store release require a supporter key; this integration targets the educational project.

`data/matching_evaluation.json` records a small development benchmark: 8/9 expected first matches. The broad query “chicken curry” returns “Nutty Chicken Curry,” illustrating that an underspecified name cannot identify an exact recipe. These examples are regression checks, not an independent accuracy study or evidence of calorie accuracy. Additional tests cover singular ingredient names, missing-energy foods, invalid weights, recipe totals, manual labels, and missing ingredients.

The calculator leaves the user-entered daily target unchanged. The existing workout and meal advice behavior is included in this standalone copy; future changes in other project folders are not automatically synchronized here.
