# Spanish Learning CLI

A Rust CLI for Spanish practice drills.

The first data file lives at `data/vocabulary.json` and currently contains:

- `hola` -> `hello` / `hi`

## Commands

Run a random practice prompt:

```sh
cargo run --
```

List vocabulary:

```sh
cargo run -- list
```

Choose a drill mode:

```sh
cargo run -- quiz --mode spanish-to-english
cargo run -- quiz --mode english-to-spanish
cargo run -- quiz --mode audio-to-spanish
```

Generate ElevenLabs audio:

```sh
cargo run -- generate-audio --api-key-file seven_eleven_key
```

The API key file is passed in explicitly and is ignored by Git. Generated audio is written to `data/audio/`, which is also ignored because it can be regenerated from the vocabulary data.
