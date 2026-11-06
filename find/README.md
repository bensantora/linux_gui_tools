# find-gui - find files by name or content

Type a word or series of letters; every file in `/home` whose name or contents contain it is listed.

## Requirements

`yad`, `find` and `grep` (standard), `xdg-open` (package `xdg-utils`).

## Use

- `./find-gui` - a small window asks for the text. Press **Search**.
- The results list shows each match and its path. Double-click a result to open it in its default app.
- **New search** goes back to the input window, **Close** quits.

## Details

- `name` means the file name contains the text; `content` means the text is inside the file.
- Case is ignored. Binary files are skipped when searching contents.
- Only `/home` is searched. To search somewhere else, change the two `/home` paths in the script.

## License

MIT - see [LICENSE](LICENSE).
