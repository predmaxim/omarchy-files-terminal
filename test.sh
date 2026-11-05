#!/bin/bash
# Open in Terminal (Files): what each right-click target offers and launches, and when the entry is hidden.
set -euo pipefail

ext="$(dirname "$0")/open-terminal.py"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir "$tmp/dir"
printf '#!/bin/bash\necho hi\n' >"$tmp/run me.sh"
chmod +x "$tmp/run me.sh"
: >"$tmp/photo.jpg"
: >"$tmp/note.txt"
: >"$tmp/empty"
cp /usr/bin/true "$tmp/prog"

python3 -I - "$ext" "$tmp" <<'EOF'
import importlib.util, os, sys
from gi.repository import Gio

spec = importlib.util.spec_from_file_location("open_terminal", sys.argv[1])
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
tmp = sys.argv[2]

class Fake:
    def __init__(self, uri, is_dir, mime=""):
        self.uri, self.is_dir, self.mime = uri, is_dir, mime
    def get_location(self):
        return Gio.File.new_for_uri(self.uri)
    def is_directory(self):
        return self.is_dir
    def get_mime_type(self):
        return self.mime

def local(name, is_dir=False, mime="text/plain"):
    return Fake(Gio.File.new_for_path(f"{tmp}/{name}").get_uri(), is_dir, mime)

mod.UWSM_APP, mod.TERMINAL = "/usr/bin/uwsm-app", "/usr/bin/xdg-terminal-exec"
mod.DEFAULT_EDITOR = f"{tmp}/editor"
a = mod.OpenInTerminalAction()

assert mod.menu_action(local("dir", True)) == ("open_folder", "Open in Terminal", [f"--dir={tmp}/dir"])
assert mod.menu_action(local("run me.sh", mime="application/x-shellscript")) == (
    "run", "Run in Terminal",
    [f"--dir={tmp}", "--", "bash", "-c", '"$1"; exec bash', "bash", f"{tmp}/run me.sh"])

assert mod.menu_action(local("prog", mime="application/x-executable"))[1] == "Run in Terminal"
# A +x picture is not a program.
os.chmod(f"{tmp}/photo.jpg", 0o755)
assert mod.menu_action(local("photo.jpg", mime="image/jpeg")) is None
os.chmod(f"{tmp}/photo.jpg", 0o644)

# Text and empty files open in the editor; no editor chosen, or a GUI one: nvim.
assert mod.menu_action(local("note.txt", mime="application/json")) == ("edit", "Edit in Neovim", [f"--dir={tmp}", "--", "nvim", f"{tmp}/note.txt"])
assert mod.menu_action(local("empty", mime="application/x-zerosize"))[1] == "Edit in Neovim"
# Pictures (SVG included), PDFs, videos get nothing.
for mime in ["image/jpeg", "image/svg+xml", "application/pdf", "video/mp4"]:
    assert mod.menu_action(local("photo.jpg", mime=mime)) is None, mime
open(mod.DEFAULT_EDITOR, "w").write("zeditor\n")
assert mod.terminal_editor() == "nvim"
open(mod.DEFAULT_EDITOR, "w").write("vim\n")
assert mod.terminal_editor() == ("vim" if mod.shutil.which("vim") else "nvim")

assert mod.menu_action(Fake("trash:///x", True)) is None
assert a.get_file_items([local("dir", True), local("photo.jpg")]) == []
folder = a.get_file_items([local("dir", True)])
here = a.get_background_items(local("dir", True))
assert len(folder) == len(here) == 1
assert folder[0].props.name != here[0].props.name
assert a.get_background_items(Fake("sftp://host/x", True)) == []

mod.TERMINAL = None
assert a.get_background_items(local("dir", True)) == []
print("ok")
EOF
