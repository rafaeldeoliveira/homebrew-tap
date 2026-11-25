# rafaeldeoliveira/tap

Homebrew formulae maintained by Rafael de Oliveira.

| Formula | Description |
|---|---|
| `gnome-text-editor` | [GNOME Text Editor](https://apps.gnome.org/TextEditor/), the simple, modern text editor from GNOME, built for macOS |
| `nautilus` | [Files](https://apps.gnome.org/Nautilus/) (Nautilus), GNOME's file manager, built for macOS |

## GNOME Text Editor

```sh
brew install rafaeldeoliveira/tap/gnome-text-editor
```

This builds GNOME's release plus macOS changes, such as Command-based
keyboard shortcuts, from
[rafaeldeoliveira/gnome-text-editor](https://github.com/rafaeldeoliveira/gnome-text-editor/tree/macos)
against Homebrew's GTK 4 and libadwaita, and creates a `Text Editor.app`
with the app icon. To add it to your Applications folder:

```sh
cp -R "$(brew --prefix)/opt/gnome-text-editor/Text Editor.app" /Applications/
```

The copied app keeps working across `brew upgrade`, since it launches the
current Homebrew build. You can also run `gnome-text-editor` from a terminal.

Other commands:

```sh
brew upgrade gnome-text-editor          # update
brew install --HEAD rafaeldeoliveira/tap/gnome-text-editor   # latest development version
brew uninstall gnome-text-editor
```

Issues with the editor itself belong
[upstream](https://gitlab.gnome.org/GNOME/gnome-text-editor/-/issues); issues with
building or running it on macOS belong in this repository.

## Files (Nautilus)

```sh
brew install rafaeldeoliveira/tap/nautilus
```

This builds GNOME's release plus macOS changes from
[rafaeldeoliveira/nautilus](https://github.com/rafaeldeoliveira/nautilus/tree/macos)
and creates a `Files.app`. To add it to your Applications folder (as a
link, so it follows upgrades):

```sh
ln -sf "$(brew --prefix)/opt/nautilus/Files.app" /Applications/
```

Shortcuts follow Finder where GNOME's would clash with macOS: for example
Command-Shift-. shows hidden files, Command-[ and Command-] go back and
forward, Command-Up opens the enclosing folder and Command-Backspace
moves to the Trash.

As in Finder, applications and other packages open instead of showing
their contents (right-click › Show Package Contents to browse inside),
and Quick Look provides thumbnails and application icons.

### The Trash

macOS only lets apps read the Trash with Full Disk Access. To browse,
restore, delete from and empty the Trash in Files, add `Files.app` in
System Settings › Privacy & Security › Full Disk Access. Without it, the
Trash opens in Finder and Empty Trash asks Finder to do it.

Files isn't signed by an Apple developer, so macOS forgets the grant
when it is upgraded: add it again after `brew upgrade`.

Items you trash in Files can be restored to where they were. Items
trashed in Finder show up too, but have to be moved back by hand.

Not available on macOS yet: the Network view, "Set as Background" and
"Send to…".

## Using a Brewfile

```ruby
tap "rafaeldeoliveira/tap"
brew "gnome-text-editor"
brew "nautilus"
```

## Documentation

`brew help`, `man brew` or check [Homebrew's documentation](https://docs.brew.sh).
