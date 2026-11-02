# rec-gui - screen recorder

Records the whole screen plus the sound you hear (not the microphone), with one button.

## Requirements

`yad`, `ffmpeg` (with x11grab and pulse support), `xdpyinfo` (package `x11-utils`), `pactl`
(PulseAudio or PipeWire-Pulse). Optional: `notify-send`.

## Use

- `./rec-gui` - a small window: **Record**, then **Stop**.
- `./rec-gui --now` - starts at once with no window, so nothing of the tool is in the picture.
- Run `./rec-gui` again while recording to stop it. Bind it to a keyboard shortcut and no window
  ever needs to be on screen.

Files are saved in your home folder as `video1.mkv`, `video2.mkv`, ... and an earlier file is never overwritten.

## Details

- Video is H.264 (30 fps), audio is lossless FLAC, in a Matroska (`.mkv`) file.
- Audio is always the current default output (`@DEFAULT_MONITOR@`), so it follows your headphones.
- The sound is delayed slightly to match how players hold back the picture (0.145 s normally,
  0.26 s on Bluetooth). If sound and picture drift apart on your setup, change the two `delay=` values near the top of the loop.

## License

MIT - see [LICENSE](LICENSE).
