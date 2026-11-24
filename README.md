# rafaeldeoliveira/tap

Homebrew formulae maintained by Rafael de Oliveira.

| Formula | Description |
|---|---|
| `gnome-text-editor` | [GNOME Text Editor](https://apps.gnome.org/TextEditor/), the simple, modern text editor from GNOME, built for macOS |

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

## Using a Brewfile

```ruby
tap "rafaeldeoliveira/tap"
brew "gnome-text-editor"
```

## Documentation

`brew help`, `man brew` or check [Homebrew's documentation](https://docs.brew.sh).
