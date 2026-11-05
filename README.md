# Files terminal

Terminal entries in the right-click menu of Files (Nautilus) on Omarchy, as in Fedora, plus running and editing files. A single [nautilus-python](https://gitlab.gnome.org/GNOME/nautilus-python) extension, no build.

| Right-click on | Entry | What it does |
|---|---|---|
| A folder, or the empty space of the current one | **Open in Terminal** | Opens a terminal in that folder |
| An executable: a program or a script with the `+x` bit | **Run in Terminal** | Runs it in its folder; the shell stays open afterwards, so the output can be read |
| A text file (code, configs, JSON, Markdown…) or an empty file | **Edit in Neovim** | Opens it in the terminal editor, in its folder |
| Anything else: pictures (SVG too), PDFs, videos, archives | — | No entry: there is nothing to do with it in a terminal |

- **Terminal**: `uwsm-app -- xdg-terminal-exec`, the same launcher as `omarchy-launch-terminal`, so it follows `omarchy default terminal` and works with alacritty, foot, ghostty and kitty.
- **Editor**: `omarchy default editor` when it runs in a terminal (nvim, vim, nano, micro, helix, fresh) and the entry is named after it ("Edit in Vim"); with a GUI editor chosen (Zed, VSCode…) it is Neovim.
- **File types** come from the MIME type Files reports. Run: `+x` and a type that can be executable (`application/x-executable`, any text type for scripts), so a picture with `+x` gets nothing. Edit: a subtype of `text/plain` other than `image/*`, or an empty file.
- **No entry** with several items selected, or in places without a local path (`trash:`, `sftp:`, `recent:`).

## Install

```bash
git clone https://github.com/predmaxim/omarchy-files-terminal ~/Projects/omarchy/own/omarchy-files-terminal
~/Projects/omarchy/own/omarchy-files-terminal/install.sh
```

`install.sh` runs the test and links `open-terminal.py` into `~/.local/share/nautilus-python/extensions/`. Files loads extensions only at startup: close all its windows (or run `nautilus -q`); a new window opened while Files is still running stays on the old code.

Upgrade: `git pull`, then restart Files. Remove: `rm ~/.local/share/nautilus-python/extensions/open-terminal.py`, then restart Files.

Omarchy updates do not touch it: the package writes to `/usr/share/omarchy` and `/etc/skel`, and its migrations copy only their own files (`localsend.py`, `transcode.py`) into the extensions folder.

## Notes

- The folder entry follows upstream PR [omacom/omarchy#7363](https://github.com/omacom/omarchy/pull/7363). If Omarchy ships it (`terminal.py` in the same folder), folders get two "Open in Terminal" entries: drop the folder part here.
- The folder and background entries have different item names on purpose: Nautilus names each action `extension_extensions_<index>_<name>` in one action group for both menus, so equal names at the same index let the background entry replace the folder one.
- A terminal that does not open: each click is logged as `received: app -- /usr/bin/xdg-terminal-exec …` in `journalctl --user`. A folder that is gone by then (a temporary one, like `/tmp/gnome-desktop-thumbnailer-*`) makes foot exit with `not a directory`.
- FAT and NTFS mounts mark every file `+x`, so a text file there gets "Run in Terminal" instead of "Edit"; pictures there still get nothing.

## Test

```bash
./test.sh
```

Builds a folder, a `+x` script, a program and plain files in a temporary directory, and checks the entry and the `xdg-terminal-exec` arguments for each, the hidden cases, and the editor choice.

## License

MIT
