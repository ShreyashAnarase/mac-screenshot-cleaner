# Mac Screenshot Cleaner

A small, dependency-free macOS utility for reviewing Desktop screenshots one
at a time and moving selected files to Trash.

## Use

1. Download `clean-screenshots.command`.
2. In Terminal, make it executable:

   ```sh
   chmod +x clean-screenshots.command
   ```

3. Double-click the file, or run it from Terminal:

   ```sh
   ./clean-screenshots.command
   ```

Preview displays each screenshot. Enter `k` to keep it, `d` to mark it for
deletion, or `q` to stop reviewing. The script asks for final confirmation,
then moves selected files to macOS Trash so they remain recoverable.

By default it reviews screenshot files directly on `~/Desktop`. To review a
different folder, pass its path:

```sh
./clean-screenshots.command "/path/to/folder"
```

## Requirements

- macOS
- Zsh, Preview, Finder, and AppleScript (all included with macOS)
