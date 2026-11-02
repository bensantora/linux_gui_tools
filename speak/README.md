# speak - text to speech

Turn text into a natural-sounding MP3 or WAV using [Piper](https://github.com/rhasspy/piper), entirely offline.

- `speak-gui` - a window: paste text, pick a voice, **Play** it or **Save MP3...**
- `speak` - the command-line tool the window uses

## Requirements

- `yad`, `ffmpeg`, `mpv`
- [Piper](https://github.com/rhasspy/piper/releases) unpacked in `~/.local/share/piper` (so that
  `~/.local/share/piper/piper` exists), or set `PIPER_DIR` to another location
- Voice files (`.onnx` + `.onnx.json`) in `PIPER_DIR/voices/`. The built-in names expect:

| Name | Voice file |
|---|---|
| `cori` (default) | `en_GB-cori-high` |
| `lessac` | `en_US-lessac-high` |
| `hfc` | `en_US-hfc_female-medium` |
| `amy` | `en_US-amy-medium` |

Any other voice file in that folder can be used by giving its name, e.g. `speak -v en_US-ryan-high ...`.
Voices are from the [Piper voices](https://huggingface.co/rhasspy/piper-voices) collection.

## Use

Window: run `./speak-gui`. Paste text, then **Play**, **Save MP3...** (type a name; a plain name goes in
your home folder) or **Voice...** to change voice.

Command line:

```
./speak notes.txt                 # -> notes.mp3 next to the text file
./speak notes.txt out.mp3         # choose the output file (.wav also works)
echo "hello" | ./speak - hi.mp3   # text from a pipe
./speak -p notes.txt              # also play it when done
./speak -v lessac notes.txt       # another voice
```

The output is polished with ffmpeg (warmer EQ, gentle compression, light room sound, -16 LUFS loudness).
Small fixes are applied to casual writing: line breaks become spaces, a lone lowercase "i" becomes "I",
" - " becomes a pause, and sentences start with a capital.

## License

MIT - see [LICENSE](LICENSE).
