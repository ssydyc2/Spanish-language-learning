use std::{
    fs,
    io::{self, Write},
    path::{Path, PathBuf},
    process::{Command, Stdio},
};

use anyhow::{anyhow, bail, Context, Result};
use clap::{Parser, Subcommand, ValueEnum};
use rand::seq::SliceRandom;
use serde::{Deserialize, Serialize};

const DEFAULT_DATA_PATH: &str = "data/vocabulary.json";
const DEFAULT_VOICE_ID: &str = "JBFqnCBsd6RMkjVDRZzb";
const DEFAULT_MODEL_ID: &str = "eleven_multilingual_v2";
const DEFAULT_OUTPUT_FORMAT: &str = "mp3_44100_128";

#[derive(Parser, Debug)]
#[command(
    name = "spanish",
    version,
    about = "A focused Spanish practice CLI with text and audio drills.",
    arg_required_else_help = false
)]
struct Cli {
    /// Vocabulary JSON file to use.
    #[arg(short, long, global = true, default_value = DEFAULT_DATA_PATH)]
    data: PathBuf,

    #[command(subcommand)]
    command: Option<Commands>,
}

#[derive(Subcommand, Debug)]
enum Commands {
    /// Start a random quiz prompt.
    Quiz {
        /// Choose a specific drill mode instead of random.
        #[arg(short, long, value_enum, default_value_t = DrillMode::Random)]
        mode: DrillMode,
    },
    /// Show the current vocabulary data.
    List,
    /// Generate missing Spanish audio files with ElevenLabs.
    GenerateAudio {
        /// File containing the ElevenLabs API key. The file is not committed.
        #[arg(long)]
        api_key_file: PathBuf,

        /// ElevenLabs voice ID to use.
        #[arg(long, default_value = DEFAULT_VOICE_ID)]
        voice_id: String,

        /// ElevenLabs model ID to use.
        #[arg(long, default_value = DEFAULT_MODEL_ID)]
        model_id: String,

        /// ElevenLabs output format.
        #[arg(long, default_value = DEFAULT_OUTPUT_FORMAT)]
        output_format: String,

        /// Directory for generated audio files.
        #[arg(long, default_value = "data/audio")]
        output_dir: PathBuf,

        /// Regenerate files even when audio already exists.
        #[arg(long)]
        overwrite: bool,
    },
}

#[derive(Copy, Clone, Debug, Eq, PartialEq, ValueEnum)]
enum DrillMode {
    Random,
    SpanishToEnglish,
    EnglishToSpanish,
    AudioToSpanish,
}

#[derive(Debug, Deserialize, Serialize)]
struct Vocabulary {
    version: u32,
    items: Vec<VocabItem>,
}

#[derive(Debug, Deserialize, Serialize)]
struct VocabItem {
    id: String,
    kind: ItemKind,
    spanish: String,
    english: Vec<String>,
    audio: Option<PathBuf>,
}

#[derive(Debug, Deserialize, Serialize)]
#[serde(rename_all = "snake_case")]
enum ItemKind {
    Word,
    Sentence,
}

#[derive(Debug, Serialize)]
struct SpeechRequest<'a> {
    text: &'a str,
    model_id: &'a str,
    language_code: &'a str,
}

fn main() -> Result<()> {
    let cli = Cli::parse();

    match cli.command.unwrap_or(Commands::Quiz {
        mode: DrillMode::Random,
    }) {
        Commands::Quiz { mode } => run_quiz(&cli.data, mode),
        Commands::List => list_items(&cli.data),
        Commands::GenerateAudio {
            api_key_file,
            voice_id,
            model_id,
            output_format,
            output_dir,
            overwrite,
        } => generate_audio(
            &cli.data,
            &api_key_file,
            &voice_id,
            &model_id,
            &output_format,
            &output_dir,
            overwrite,
        ),
    }
}

fn run_quiz(data_path: &Path, mode: DrillMode) -> Result<()> {
    let vocabulary = read_vocabulary(data_path)?;
    let item = vocabulary
        .items
        .choose(&mut rand::thread_rng())
        .ok_or_else(|| anyhow!("no vocabulary items found in {}", data_path.display()))?;
    let mode = pick_mode(mode, item);

    println!("Spanish practice");
    println!("----------------");

    let expected_answers = match mode {
        DrillMode::SpanishToEnglish => {
            println!("Translate to English:");
            println!();
            println!("  {}", item.spanish);
            item.english.iter().map(String::as_str).collect::<Vec<_>>()
        }
        DrillMode::EnglishToSpanish => {
            println!("Translate to Spanish:");
            println!();
            println!(
                "  {}",
                item.english
                    .first()
                    .context("item has no English translation")?
            );
            vec![item.spanish.as_str()]
        }
        DrillMode::AudioToSpanish => {
            println!("Listen and type the Spanish:");
            println!();
            play_item_audio(data_path, item)?;
            vec![item.spanish.as_str()]
        }
        DrillMode::Random => unreachable!("random mode should be resolved before prompting"),
    };

    print!("\nAnswer: ");
    io::stdout().flush().context("failed to flush prompt")?;

    let mut answer = String::new();
    io::stdin()
        .read_line(&mut answer)
        .context("failed to read answer")?;

    if is_correct(&answer, &expected_answers) {
        println!("Correct.");
    } else {
        println!("Not quite.");
        println!("Spanish: {}", item.spanish);
        println!("English: {}", item.english.join(" / "));
    }

    Ok(())
}

fn list_items(data_path: &Path) -> Result<()> {
    let vocabulary = read_vocabulary(data_path)?;

    println!(
        "{} item(s) in {}",
        vocabulary.items.len(),
        data_path.display()
    );
    for item in vocabulary.items {
        let audio = item
            .audio
            .as_ref()
            .map(|path| path.display().to_string())
            .unwrap_or_else(|| "no audio yet".to_string());

        println!(
            "- {} [{}] -> {} ({})",
            item.spanish,
            item.id,
            item.english.join(" / "),
            audio
        );
    }

    Ok(())
}

fn generate_audio(
    data_path: &Path,
    api_key_file: &Path,
    voice_id: &str,
    model_id: &str,
    output_format: &str,
    output_dir: &Path,
    overwrite: bool,
) -> Result<()> {
    let mut vocabulary = read_vocabulary(data_path)?;
    let api_key = read_api_key(api_key_file)?;
    fs::create_dir_all(output_dir)
        .with_context(|| format!("failed to create {}", output_dir.display()))?;

    let mut generated = 0usize;
    for item in &mut vocabulary.items {
        let output_file = output_dir.join(format!("{}.mp3", safe_file_stem(&item.id)));
        let audio_for_data = relative_to_data_file(data_path, &output_file);

        if !overwrite && item.audio.is_some() && output_file.exists() {
            continue;
        }

        println!("Generating audio for {}", item.spanish);
        let bytes = request_speech(&api_key, voice_id, model_id, output_format, &item.spanish)?;

        fs::write(&output_file, bytes)
            .with_context(|| format!("failed to write {}", output_file.display()))?;
        item.audio = Some(audio_for_data);
        generated += 1;
    }

    if generated > 0 {
        write_vocabulary(data_path, &vocabulary)?;
    }

    println!("Generated {generated} audio file(s).");
    Ok(())
}

fn request_speech(
    api_key: &str,
    voice_id: &str,
    model_id: &str,
    output_format: &str,
    text: &str,
) -> Result<Vec<u8>> {
    let url = format!(
        "https://api.elevenlabs.io/v1/text-to-speech/{voice_id}?output_format={output_format}"
    );
    let request = SpeechRequest {
        text,
        model_id,
        language_code: "es",
    };
    let body = serde_json::to_string(&request).context("failed to serialize speech request")?;
    let curl_config = format!(
        "silent\nshow-error\nfail-with-body\nlocation\nrequest = \"POST\"\nurl = {}\nheader = {}\nheader = \"Content-Type: application/json\"\ndata = {}\n",
        curl_quote(&url),
        curl_quote(&format!("xi-api-key: {api_key}")),
        curl_quote(&body)
    );

    let mut child = Command::new("curl")
        .arg("--config")
        .arg("-")
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .context("failed to start curl; install curl or generate audio separately")?;

    child
        .stdin
        .as_mut()
        .context("failed to open curl stdin")?
        .write_all(curl_config.as_bytes())
        .context("failed to write curl config")?;

    let output = child.wait_with_output().context("failed to run curl")?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        let stdout = String::from_utf8_lossy(&output.stdout);
        bail!("ElevenLabs request failed: {stderr}{stdout}");
    }

    Ok(output.stdout)
}

fn read_vocabulary(path: &Path) -> Result<Vocabulary> {
    let contents =
        fs::read_to_string(path).with_context(|| format!("failed to read {}", path.display()))?;
    serde_json::from_str(&contents)
        .with_context(|| format!("failed to parse vocabulary JSON in {}", path.display()))
}

fn write_vocabulary(path: &Path, vocabulary: &Vocabulary) -> Result<()> {
    let contents =
        serde_json::to_string_pretty(vocabulary).context("failed to serialize vocabulary JSON")?;
    fs::write(path, format!("{contents}\n"))
        .with_context(|| format!("failed to write {}", path.display()))
}

fn read_api_key(path: &Path) -> Result<String> {
    let key =
        fs::read_to_string(path).with_context(|| format!("failed to read {}", path.display()))?;
    let key = key.trim().to_string();
    if key.is_empty() {
        bail!("{} is empty", path.display());
    }
    Ok(key)
}

fn pick_mode(requested: DrillMode, item: &VocabItem) -> DrillMode {
    if requested != DrillMode::Random {
        return requested;
    }

    let mut modes = vec![DrillMode::SpanishToEnglish, DrillMode::EnglishToSpanish];
    if item.audio.is_some() {
        modes.push(DrillMode::AudioToSpanish);
    }

    *modes
        .choose(&mut rand::thread_rng())
        .expect("mode list is never empty")
}

fn play_item_audio(data_path: &Path, item: &VocabItem) -> Result<()> {
    let audio = item
        .audio
        .as_ref()
        .ok_or_else(|| anyhow!("{} does not have audio yet", item.id))?;
    let audio_path = resolve_from_data_file(data_path, audio);

    if !audio_path.exists() {
        bail!("audio file does not exist: {}", audio_path.display());
    }

    play_audio(&audio_path)
}

fn play_audio(path: &Path) -> Result<()> {
    let candidates: &[(&str, &[&str])] = if cfg!(target_os = "macos") {
        &[("afplay", &[])]
    } else if cfg!(target_os = "windows") {
        &[("powershell", &["-NoProfile", "-Command", "Start-Process"])]
    } else {
        &[("ffplay", &["-nodisp", "-autoexit"]), ("mpg123", &[])]
    };

    for (program, args) in candidates {
        let status = Command::new(program).args(*args).arg(path).status();

        if let Ok(status) = status {
            if status.success() {
                return Ok(());
            }
        }
    }

    bail!(
        "could not play audio automatically; open this file manually: {}",
        path.display()
    )
}

fn is_correct(answer: &str, expected_answers: &[&str]) -> bool {
    let answer = normalize_answer(answer);
    expected_answers
        .iter()
        .any(|expected| answer == normalize_answer(expected))
}

fn normalize_answer(input: &str) -> String {
    input
        .trim()
        .trim_matches(|c: char| matches!(c, '.' | ',' | '!' | '?' | '¡' | '¿'))
        .to_lowercase()
}

fn curl_quote(input: &str) -> String {
    let mut output = String::from("\"");
    for ch in input.chars() {
        match ch {
            '\\' => output.push_str("\\\\"),
            '"' => output.push_str("\\\""),
            '\n' => output.push_str("\\n"),
            '\r' => output.push_str("\\r"),
            '\t' => output.push_str("\\t"),
            ch => output.push(ch),
        }
    }
    output.push('"');
    output
}

fn safe_file_stem(input: &str) -> String {
    let mut output = String::new();
    for ch in input.chars() {
        if ch.is_ascii_alphanumeric() {
            output.push(ch.to_ascii_lowercase());
        } else if !output.ends_with('-') {
            output.push('-');
        }
    }
    output.trim_matches('-').to_string()
}

fn relative_to_data_file(data_path: &Path, output_file: &Path) -> PathBuf {
    let data_dir = data_path.parent().unwrap_or_else(|| Path::new("."));
    pathdiff::diff_paths(output_file, data_dir).unwrap_or_else(|| output_file.to_path_buf())
}

fn resolve_from_data_file(data_path: &Path, audio: &Path) -> PathBuf {
    if audio.is_absolute() {
        audio.to_path_buf()
    } else {
        data_path
            .parent()
            .unwrap_or_else(|| Path::new("."))
            .join(audio)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn answer_matching_is_case_and_punctuation_insensitive() {
        assert!(is_correct(" Hello! ", &["hello"]));
        assert!(is_correct("¿hola?", &["hola"]));
        assert!(!is_correct("goodbye", &["hello"]));
    }

    #[test]
    fn file_stems_are_stable() {
        assert_eq!(safe_file_stem("Hola, mundo!"), "hola-mundo");
    }

    #[test]
    fn curl_values_are_quoted() {
        assert_eq!(
            curl_quote("a \"quoted\" value"),
            "\"a \\\"quoted\\\" value\""
        );
    }
}
