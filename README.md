# Spanish Quest

Spanish Quest contains a Rust CLI for vocabulary practice and a Godot 4 village-learning game prototype.

## Rust CLI

The first data file lives at `data/vocabulary.json` and currently contains:

- `hola` -> `hello` / `hi`

## Commands

Open the interactive menu:

```sh
cargo run --
```

From the menu, choose quiz, list words, generate audio, or exit.
The menu uses arrow-key selection, color, and short descriptions for each action.

List vocabulary:

```sh
cargo run -- list
```

For each prompt, the quiz first chooses a random word or sentence, then chooses one random drill mode available for that item: Spanish to English, English to Spanish, or audio to Spanish when audio exists. Quiz mode keeps going until you press Ctrl+D.

```sh
cargo run -- quiz
```

Generate ElevenLabs audio:

```sh
cargo run -- generate-audio --api-key-file seven_eleven_key
```

The API key file is passed in explicitly and is ignored by Git. Audio files are written to `data/audio/` and committed with the vocabulary so audio drills work without regenerating everything on each checkout.

By default, `generate-audio` reuses existing audio files. Pass `--overwrite` when you intentionally want to regenerate them.

Generate the Godot number-course audio:

```sh
cargo run -- --data godot/data/courses/numbers.json generate-audio --api-key-file seven_eleven_key
```

The number course stores audio paths under `godot/data/audio/numbers/` so the teacher's number lesson can use the same generated MP3 files for explanation examples and listening drills.

## Godot village prototype

The new game-first prototype lives in `godot/` and is intended to become the main implementation for the village learning experience.

It currently includes:

- a Godot 4 project with `res://scenes/Main.tscn` as the entry scene
- HD 2D village, school, cafe, and library backgrounds
- a normal player character and scholar NPC sprite
- free player movement with keyboard, tap-to-move, and a circular mobile joystick
- camera follow and zoom controls
- data-driven walkable areas so the player stays on roads/open floor regions
- enterable school, cafe, and library scenes
- a scholar inside the library who opens a simple Spanish quiz
- a teacher inside the school who opens course study, starting with a Spanish numbers course
- vocabulary and audio copied from `data/vocabulary.json` and `data/audio/`
- a number-course data file at `godot/data/courses/numbers.json`

Open it with Godot 4:

```sh
godot4 --path godot
```

If your Godot binary is named `godot`, use:

```sh
godot --path godot
```

Run a headless smoke test:

```sh
godot --headless --path godot --quit-after 2
```

The app logic is intentionally small and data-driven:

- `godot/scripts/Main.gd`: village maps, player movement, camera, portals, NPC interaction
- `godot/scripts/VirtualJoystick.gd`: mobile movement control
- `godot/scripts/QuizPanel.gd`: scholar quiz UI and vocabulary loading
- `godot/scripts/NumberLessonPanel.gd`: teacher number rules and number drills
