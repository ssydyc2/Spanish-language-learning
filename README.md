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
