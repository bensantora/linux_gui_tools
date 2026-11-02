# ebook - write a book as plain text, get an .epub

A small window (`app/ebook-gui`) around a Python engine (`app/ebook`). Chapters are plain `.txt` files;
the `.epub` is rebuilt from scratch on every build, with a generated cover, title page, copyright page and
table of contents. Never edit the `.epub` itself.

## Requirements

`yad`, `python3`, `python3-pil` (for the generated cover; DejaVu Serif font), an editor (default `geany`),
and an EPUB reader to preview (default `ebook-viewer` from Calibre).

Change them with environment variables: `EDITOR_CMD=gedit ./app/ebook-gui`, `EBOOK_VIEWER=okular ./app/ebook-gui`.

## Use

```
./app/ebook-gui
```

Pick or create a book, then use the buttons: Edit, New chapter, Rename, Up/Down (order), Delete
(moved to a `.trash` folder, not erased), Book info, Build book (makes the `.epub` and opens it).

Books live in `books/<name>/` next to `app/`: `book.conf`, `order.txt` and `chapters/*.txt`.
An example book is included: `books/lantern-keepers-almanac`.

### Chapter text format

```
First line of a file = the chapter title
(blank line = new paragraph)
## Words                = a section heading
*italic*   **bold**
* * *                   = a break between scenes
```

### Command line

```
./app/ebook books                      # list books
./app/ebook newbook "Title" "Author"
./app/ebook list BOOK                  # chapters with word counts
./app/ebook build BOOK                 # writes books/BOOK.epub
```
(also `new`, `rename`, `move`, `delete`, `info`, `setinfo`)

## License

MIT - see [LICENSE](LICENSE).
