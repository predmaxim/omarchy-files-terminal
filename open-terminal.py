import os
import shutil

from gi import require_version

require_version("Nautilus", "4.1")

from gi.repository import GObject, Gio, Nautilus

# The same launcher as omarchy-launch-terminal: xdg-terminal-exec follows
# `omarchy default terminal`, and --dir works for every terminal (it falls back
# to chdir before exec). Folder part based on upstream PR omacom/omarchy#7363.
UWSM_APP = shutil.which("uwsm-app")
TERMINAL = shutil.which("xdg-terminal-exec")

# The editors omarchy-launch-editor runs in a terminal, with their menu names.
TERMINAL_EDITORS = {
    "nvim": "Neovim",
    "vim": "Vim",
    "nano": "nano",
    "micro": "micro",
    "hx": "Helix",
    "helix": "Helix",
    "fresh": "Fresh",
}
DEFAULT_EDITOR = os.path.expanduser("~/.local/state/omarchy/defaults/editor")


def terminal_editor():
    """`omarchy default editor` if it runs in a terminal, otherwise nvim."""
    try:
        with open(DEFAULT_EDITOR) as f:
            editor = f.read().strip()
    except OSError:
        editor = ""
    if editor in TERMINAL_EDITORS and shutil.which(editor):
        return editor
    return "nvim"


def menu_action(file):
    """(name, label, xdg-terminal-exec args) for what was right-clicked, or None."""
    location = file.get_location()
    path = location.get_path() if location else None
    # trash:, sftp:, recent: have no local path to hand a terminal.
    if not path:
        return None

    if file.is_directory():
        return "open_folder", "Open in Terminal", [f"--dir={path}"]

    folder = f"--dir={os.path.dirname(path)}"
    mime = file.get_mime_type() or ""
    # Programs (application/x-executable) and scripts (text types), not a +x
    # photo. shortcut: FAT/NTFS mounts mark every file +x, so a text file there
    # gets "Run in Terminal" instead of "Edit"; check for a shebang if it matters.
    if os.access(path, os.X_OK) and Gio.content_type_can_be_executable(mime):
        # The shell stays open after the program exits, to read its output.
        return "run", "Run in Terminal", [folder, "--", "bash", "-c", '"$1"; exec bash', "bash", path]

    # Only text is worth an editor: code, configs, JSON, empty files. SVG is
    # XML text too, but it is a picture to the user.
    editable = Gio.content_type_is_a(mime, "text/plain") and not mime.startswith("image/")
    if not editable and mime != "application/x-zerosize":
        return None

    editor = terminal_editor()
    return "edit", f"Edit in {TERMINAL_EDITORS[editor]}", [folder, "--", editor, path]


class OpenInTerminalAction(GObject.GObject, Nautilus.MenuProvider):
    def _items(self, action, name=None):
        if not action or not UWSM_APP or not TERMINAL:
            return []

        action_name, label, args = action
        item = Nautilus.MenuItem(
            name=f"PredmaximTerminalNautilus::{name or action_name}",
            label=label,
            icon="utilities-terminal",
        )
        item.connect("activate", self._on_activate, args)
        return [item]

    def _on_activate(self, _menu, args):
        Gio.Subprocess.new([UWSM_APP, "--", TERMINAL, *args], Gio.SubprocessFlags.NONE)

    def get_file_items(self, *args):
        files = args[-1]
        # Several selected items have no single thing to open.
        return self._items(menu_action(files[0])) if len(files) == 1 else []

    # Nautilus names each item's action "extension_extensions_<index>_<name>" in
    # one action group for both menus, so equal names at the same index let the
    # background item replace the folder one: keep the two names different.
    def get_background_items(self, *args):
        return self._items(menu_action(args[-1]), "open_here")
