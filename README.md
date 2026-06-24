# Spanish Learning CLI

A Rust CLI for Spanish practice drills.

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

## Godot village prototype

The new game-first prototype lives in `godot/` and is intended to become the main implementation for the village learning experience.

It currently includes:

- a Godot 4 project with `res://scenes/Main.tscn` as the entry scene
- HD 2D village, school, cafe, and library backgrounds copied from the iOS prototype
- a normal player character and scholar NPC sprite
- free player movement with keyboard, tap-to-move, and a circular mobile joystick
- camera follow and zoom controls
- data-driven walkable areas so the player stays on roads/open floor regions
- enterable school, cafe, and library scenes
- a scholar inside the library who opens a simple Spanish quiz
- vocabulary and audio copied from `data/vocabulary.json` and `data/audio/`

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

## iOS village prototype

The first native iOS prototype lives in `ios/SpanishQuest`.

It is now a legacy native prototype kept as a reference while the game layer moves to Godot:

- the root screen is a generated HD 2D Spanish village map
- the player can move freely by dragging, tapping, or using a circular phone movement pad
- the village is scene-driven so more buildings, interiors, and characters can be added
- the school, cafe, and library are enterable buildings with generated HD 2D interior backgrounds
- the player and first scholar NPC use generated HD 2D character sprites
- the first character is a scholar inside the library
- talking with the scholar starts a simple Spanish quiz using the existing vocabulary and audio data
- the old battle prototype files are still in the project, but the app now launches into the village

Build it from the repo root:

```sh
xcodebuild -project ios/SpanishQuest/SpanishQuest.xcodeproj \
  -scheme SpanishQuest \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath ios/SpanishQuest/DerivedData \
  build
```

The app currently bundles a snapshot of `data/vocabulary.json`, `data/audio/`, and the generated art assets under `ios/SpanishQuest/SpanishQuest/Resources/`.
