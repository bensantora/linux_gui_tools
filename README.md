# Linux GUI Tools

A small collection of simple desktop tools for Linux. Each one is a plain script with an easy point-and-click
window made with [yad](https://github.com/v1cont/yad). There is no installer, no build step and no heavy
framework: download it, make the scripts executable and run them.

## What's included

- **speak** - Paste or type text, choose a voice, then play it or save it as an MP3. It works offline using
  Piper voices, and ffmpeg gives the audio a polished studio sound. There is also a command-line version for scripts.
- **rec** - A one-button screen recorder. It captures the whole screen plus the sound you hear, and saves each
  recording as a new numbered file without overwriting earlier ones. It can run with no window at all, so it
  works well with a keyboard shortcut.
- **ebook** - Write a book as plain-text chapters and build a valid EPUB with one click. It makes the cover,
  title page, copyright page and table of contents for you. A sample book is included.

**Requirements:** Linux with X11, `bash` and `yad`. Each tool lists the few extras it needs, such as `ffmpeg`,
`mpv`, Piper, Python 3 or Calibre's viewer.

| Tool | What it does |
|---|---|
| [`speak/`](speak/) | Paste text, hear it or save it as a polished MP3 (offline voices via Piper) |
| [`rec/`](rec/) | Record the whole screen plus the sound you hear, one button |
| [`ebook/`](ebook/) | Write an ebook as plain-text chapters and build a valid `.epub` with one click |
| [`picture-sound-mp4/`](picture-sound-mp4/) | One picture + one sound file = an MP4 as long as the sound |

## Requirements (all tools)

- Linux with X11 (the recorder uses X11 screen capture)
- `bash`, `yad`
- Per tool: see its own README (`ffmpeg`, `mpv`, Piper, `python3`, ...)

On Debian/Ubuntu: `sudo apt install yad ffmpeg mpv python3 python3-pil geany calibre`

## Install

```
git clone <this repo>
cd linux-gui-tools
chmod +x speak/speak speak/speak-gui rec/rec-gui ebook/app/ebook ebook/app/ebook-gui
```

Run any tool straight from its folder, e.g. `./speak/speak-gui`. To get a menu entry or keyboard
shortcut, point it at the full path of the script (or symlink the scripts into a folder on your `PATH`;
each script finds its sibling files through the symlink).

## License

MIT - see [LICENSE](LICENSE).
