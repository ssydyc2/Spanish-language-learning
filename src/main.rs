use std::{
    fs,
    io::{self, IsTerminal, Write},
    path::{Path, PathBuf},
    process::{Command, Stdio},
};

use anyhow::{bail, Context, Result};
use clap::{Parser, Subcommand};
use console::style;
use dialoguer::{theme::ColorfulTheme, Input, Select};
use serde::{Deserialize, Serialize};
use serde_json::{Map, Value};

const DEFAULT_DATA_PATH: &str = "data/vocabulary.json";
const DEFAULT_API_KEY_FILE: &str = "seven_eleven_key";
const DEFAULT_VOICE_ID: &str = "JBFqnCBsd6RMkjVDRZzb";
const DEFAULT_MODEL_ID: &str = "eleven_multilingual_v2";
const DEFAULT_OUTPUT_FORMAT: &str = "mp3_44100_128";

#[derive(Parser, Debug)]
#[command(
    name = "spanish",
    version,
    about = "Spanish Quest asset helper for vocabulary lists and generated audio.",
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
    /// Show the complete vocabulary data.
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

#[derive(Copy, Clone, Debug, Eq, PartialEq)]
enum MenuChoice {
    ListWords,
    GenerateAudio,
    Exit,
}

struct MenuOption {
    choice: MenuChoice,
    icon: &'static str,
    title: &'static str,
    description: &'static str,
}

#[derive(Debug, Deserialize, Serialize)]
struct Vocabulary {
    version: u32,
    items: Vec<VocabItem>,
    #[serde(flatten)]
    extra: Map<String, Value>,
}

#[derive(Debug, Deserialize, Serialize)]
struct VocabItem {
    id: String,
    kind: ItemKind,
    spanish: String,
    english: Vec<String>,
    audio: Option<PathBuf>,
    #[serde(flatten)]
    extra: Map<String, Value>,
}

#[derive(Debug, Deserialize, Serialize)]
#[serde(rename_all = "snake_case")]
enum ItemKind {
    Word,
    Sentence,
    Number,
}

impl ItemKind {
    fn as_str(&self) -> &'static str {
        match self {
            Self::Word => "word",
            Self::Sentence => "sentence",
            Self::Number => "number",
        }
    }
}

#[derive(Debug, Serialize)]
struct SpeechRequest<'a> {
    text: &'a str,
    model_id: &'a str,
    language_code: &'a str,
}

fn main() -> Result<()> {
    let cli = Cli::parse();

    match cli.command {
        Some(command) => run_command(command, &cli.data),
        None => run_interactive(&cli.data),
    }
}

fn run_command(command: Commands, data_path: &Path) -> Result<()> {
    match command {
        Commands::List => list_items(data_path),
        Commands::GenerateAudio {
            api_key_file,
            voice_id,
            model_id,
            output_format,
            output_dir,
            overwrite,
        } => generate_audio(
            data_path,
            &api_key_file,
            &voice_id,
            &model_id,
            &output_format,
            &output_dir,
            overwrite,
        ),
    }
}

fn run_interactive(data_path: &Path) -> Result<()> {
    print_interactive_header(data_path);

    loop {
        match select_menu_choice()? {
            MenuChoice::ListWords => list_items(data_path)?,
            MenuChoice::GenerateAudio => {
                let api_key_file = prompt_api_key_file()?;
                generate_audio(
                    data_path,
                    Path::new(&api_key_file),
                    DEFAULT_VOICE_ID,
                    DEFAULT_MODEL_ID,
                    DEFAULT_OUTPUT_FORMAT,
                    Path::new("data/audio"),
                    false,
                )?;
            }
            MenuChoice::Exit => {
                println!("Hasta luego.");
                return Ok(());
            }
        }
    }
}

fn print_interactive_header(data_path: &Path) {
    println!();
    println!("{}", style("  █▀▀ █▀█ ▄▀█ █▄░█ █ █▀ █░█").cyan().bold());
    println!("{}", style("  ▄██ ██▄ █▀█ █░▀█ █ ▄█ █▀█").blue().bold());
    println!();
    println!("{}", style("Spanish Learning").bold().underlined());
    println!(
        "{} {}",
        style("Data:").dim(),
        style(data_path.display()).green()
    );
    println!(
        "{}",
        style("Choose a utility below to inspect vocabulary or generate audio assets.").dim()
    );
}

fn select_menu_choice() -> Result<MenuChoice> {
    let options = menu_options();

    if !io::stdin().is_terminal() {
        return select_menu_choice_from_stdin(&options);
    }

    let labels = options.iter().map(format_menu_option).collect::<Vec<_>>();

    let selection = Select::with_theme(&menu_theme())
        .with_prompt("What would you like to do?")
        .items(&labels)
        .default(0)
        .interact_opt()
        .context("failed to read menu choice")?;

    Ok(selection
        .map(|index| options[index].choice)
        .unwrap_or(MenuChoice::Exit))
}

fn select_menu_choice_from_stdin(options: &[MenuOption]) -> Result<MenuChoice> {
    println!();
    println!("What would you like to do?");
    for (index, option) in options.iter().enumerate() {
        println!("  {}) {} - {}", index + 1, option.title, option.description);
    }

    let input = read_line("Choice: ")?;
    Ok(parse_menu_choice(&input, options).unwrap_or(MenuChoice::Exit))
}

fn prompt_api_key_file() -> Result<String> {
    if !io::stdin().is_terminal() {
        let input = read_line(&format!("API key file [{DEFAULT_API_KEY_FILE}]: "))?;
        return Ok(if input.is_empty() {
            DEFAULT_API_KEY_FILE.to_string()
        } else {
            input
        });
    }

    Input::with_theme(&menu_theme())
        .with_prompt("API key file")
        .default(DEFAULT_API_KEY_FILE.to_string())
        .interact_text()
        .context("failed to read API key file")
}

fn menu_options() -> Vec<MenuOption> {
    vec![
        MenuOption {
            choice: MenuChoice::ListWords,
            icon: "▤",
            title: "List all",
            description: "Print every saved word, sentence, number, and audio path",
        },
        MenuOption {
            choice: MenuChoice::GenerateAudio,
            icon: "◈",
            title: "Generate audio",
            description: "Create missing ElevenLabs MP3s using your local key file",
        },
        MenuOption {
            choice: MenuChoice::Exit,
            icon: "□",
            title: "Exit",
            description: "Leave the asset helper",
        },
    ]
}

fn format_menu_option(option: &MenuOption) -> String {
    format!(
        "{}  {:<15} {}",
        style(option.icon).cyan().bold(),
        style(option.title).bold(),
        style(option.description).dim()
    )
}

fn menu_theme() -> ColorfulTheme {
    ColorfulTheme {
        prompt_prefix: style("▸".to_string()).cyan().bold(),
        active_item_prefix: style("▸".to_string()).cyan().bold(),
        inactive_item_prefix: style(" ".to_string()).dim(),
        checked_item_prefix: style("✓".to_string()).green().bold(),
        unchecked_item_prefix: style(" ".to_string()).dim(),
        defaults_style: console::Style::new().yellow(),
        ..ColorfulTheme::default()
    }
}

fn read_line(label: &str) -> Result<String> {
    print!("{label}");
    io::stdout().flush().context("failed to flush prompt")?;

    let mut input = String::new();
    let bytes = io::stdin()
        .read_line(&mut input)
        .context("failed to read input")?;

    if bytes == 0 {
        return Ok("exit".to_string());
    }

    Ok(input.trim().to_string())
}

fn parse_menu_choice(input: &str, options: &[MenuOption]) -> Option<MenuChoice> {
    let input = input.trim().to_lowercase();

    if let Ok(index) = input.parse::<usize>() {
        return options
            .get(index.checked_sub(1)?)
            .map(|option| option.choice);
    }

    options
        .iter()
        .find(|option| {
            input == option.title.to_lowercase()
                || input == option.title.to_lowercase().replace(' ', "-")
        })
        .map(|option| option.choice)
        .or_else(|| match input.as_str() {
            "list" | "words" | "vocabulary" | "all" => Some(MenuChoice::ListWords),
            "audio" | "generate" => Some(MenuChoice::GenerateAudio),
            "q" | "quit" => Some(MenuChoice::Exit),
            _ => None,
        })
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
            "- {} [{}; {}] -> {} ({})",
            item.spanish,
            item.id,
            item.kind.as_str(),
            item.english.join(" / "),
            audio
        );

        if !item.extra.is_empty() {
            let extra =
                serde_json::to_string(&item.extra).context("failed to serialize item metadata")?;
            println!("  extra: {extra}");
        }
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

    let mut generated = 0usize;
    let mut reused = 0usize;
    let mut updated_metadata = false;
    let mut api_key = None;

    for item in &mut vocabulary.items {
        let output_file = audio_output_path(data_path, output_dir, item);
        let audio_for_data = relative_to_data_file(data_path, &output_file);

        if !overwrite && output_file.exists() {
            if item.audio.as_ref() != Some(&audio_for_data) {
                item.audio = Some(audio_for_data);
                updated_metadata = true;
            }
            reused += 1;
            continue;
        }

        if let Some(parent) = output_file.parent() {
            fs::create_dir_all(parent)
                .with_context(|| format!("failed to create {}", parent.display()))?;
        }

        let api_key = match &api_key {
            Some(api_key) => api_key,
            None => api_key.insert(read_api_key(api_key_file)?),
        };

        println!("Generating audio for {}", item.spanish);
        let bytes = request_speech(&api_key, voice_id, model_id, output_format, &item.spanish)?;

        fs::write(&output_file, bytes)
            .with_context(|| format!("failed to write {}", output_file.display()))?;
        item.audio = Some(audio_for_data);
        updated_metadata = true;
        generated += 1;
    }

    if updated_metadata {
        write_vocabulary(data_path, &vocabulary)?;
    }

    println!("Generated {generated} audio file(s). Reused {reused} existing file(s).");
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

fn audio_output_path(data_path: &Path, output_dir: &Path, item: &VocabItem) -> PathBuf {
    item.audio
        .as_ref()
        .map(|audio| resolve_from_data_file(data_path, audio))
        .unwrap_or_else(|| output_dir.join(format!("{}.mp3", safe_file_stem(&item.id))))
}

fn relative_to_data_file(data_path: &Path, output_file: &Path) -> PathBuf {
    let data_dir = asset_data_dir(data_path);
    pathdiff::diff_paths(output_file, data_dir).unwrap_or_else(|| output_file.to_path_buf())
}

fn resolve_from_data_file(data_path: &Path, audio: &Path) -> PathBuf {
    if audio.is_absolute() {
        audio.to_path_buf()
    } else {
        asset_data_dir(data_path).join(audio)
    }
}

fn asset_data_dir(data_path: &Path) -> &Path {
    let parent = data_path.parent().unwrap_or_else(|| Path::new("."));
    if parent.file_name().and_then(|name| name.to_str()) == Some("courses") {
        if let Some(data_dir) = parent.parent() {
            return data_dir;
        }
    }
    parent
}

#[cfg(test)]
mod tests {
    use super::*;

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

    #[test]
    fn audio_target_uses_existing_metadata_path() {
        let item = VocabItem {
            id: "hola".to_string(),
            kind: ItemKind::Word,
            spanish: "hola".to_string(),
            english: vec!["hello".to_string()],
            audio: Some(PathBuf::from("audio/custom-hola.mp3")),
            extra: Map::new(),
        };

        assert_eq!(
            audio_output_path(
                Path::new("data/vocabulary.json"),
                Path::new("data/audio"),
                &item
            ),
            PathBuf::from("data/audio/custom-hola.mp3")
        );
    }

    #[test]
    fn number_items_can_be_loaded_with_extra_course_fields() {
        let item: VocabItem = serde_json::from_str(
            r#"{
                "id": "number_42",
                "kind": "number",
                "number": 42,
                "digits": "42",
                "spanish": "cuarenta y dos",
                "english": ["42"],
                "accepted_spanish": ["cuarenta y dos"],
                "audio": "audio/numbers/number_42.mp3"
            }"#,
        )
        .expect("number item should deserialize");

        assert!(matches!(item.kind, ItemKind::Number));
        assert_eq!(item.spanish, "cuarenta y dos");
        assert_eq!(item.extra.get("digits"), Some(&Value::from("42")));
    }

    #[test]
    fn vocabulary_serialization_preserves_course_fields() {
        let mut vocabulary_extra = Map::new();
        vocabulary_extra.insert(
            "lessons".to_string(),
            Value::Array(vec![Value::from("number rules")]),
        );

        let mut item_extra = Map::new();
        item_extra.insert("digits".to_string(), Value::from("42"));
        item_extra.insert(
            "accepted_spanish".to_string(),
            Value::Array(vec![Value::from("cuarenta y dos")]),
        );

        let vocabulary = Vocabulary {
            version: 1,
            items: vec![VocabItem {
                id: "number_42".to_string(),
                kind: ItemKind::Number,
                spanish: "cuarenta y dos".to_string(),
                english: vec!["42".to_string()],
                audio: Some(PathBuf::from("audio/numbers/number_42.mp3")),
                extra: item_extra,
            }],
            extra: vocabulary_extra,
        };

        let serialized = serde_json::to_value(&vocabulary).expect("serialize vocabulary");
        assert!(serialized.get("lessons").is_some());
        assert_eq!(
            serialized["items"][0].get("digits"),
            Some(&Value::from("42"))
        );
        assert!(serialized["items"][0].get("accepted_spanish").is_some());
    }

    #[test]
    fn course_audio_paths_resolve_from_godot_data_root() {
        let data_path = Path::new("godot/data/courses/numbers.json");
        let audio = Path::new("audio/numbers/number_42.mp3");

        assert_eq!(
            resolve_from_data_file(data_path, audio),
            PathBuf::from("godot/data/audio/numbers/number_42.mp3")
        );
        assert_eq!(
            relative_to_data_file(
                data_path,
                Path::new("godot/data/audio/numbers/number_42.mp3")
            ),
            PathBuf::from("audio/numbers/number_42.mp3")
        );
    }

    #[test]
    fn menu_labels_explain_each_action() {
        let labels = menu_options()
            .iter()
            .map(format_menu_option)
            .collect::<Vec<_>>();

        assert!(labels.iter().any(|label| label.contains("List all")));
        assert!(labels.iter().any(|label| label.contains("Generate audio")));
        assert!(labels.iter().any(|label| label.contains("Exit")));
    }

    #[test]
    fn menu_choices_accept_numbers_and_action_names() {
        let options = menu_options();

        assert_eq!(
            parse_menu_choice("1", &options),
            Some(MenuChoice::ListWords)
        );
        assert_eq!(
            parse_menu_choice("list", &options),
            Some(MenuChoice::ListWords)
        );
        assert_eq!(
            parse_menu_choice("2", &options),
            Some(MenuChoice::GenerateAudio)
        );
        assert_eq!(
            parse_menu_choice("generate-audio", &options),
            Some(MenuChoice::GenerateAudio)
        );
        assert_eq!(parse_menu_choice("3", &options), Some(MenuChoice::Exit));
        assert_eq!(parse_menu_choice("quit", &options), Some(MenuChoice::Exit));
        assert_eq!(parse_menu_choice("quiz", &options), None);
        assert_eq!(parse_menu_choice("practice", &options), None);
        assert_eq!(parse_menu_choice("wat", &options), None);
    }
}
