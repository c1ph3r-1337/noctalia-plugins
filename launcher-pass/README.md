# launcher-pass

A Noctalia launcher provider plugin for GNU Pass password store.

## Features

- Browse password store directories
- Fuzzy search across all passwords (spaces treated as wildcards)
- Navigate subdirectories
- Copy/type password or any field from password entries
- Quick access via `>pass` command
- Configurable password store path

## Usage

1. Open the launcher with your configured keybind
2. Type `>pass` to access the plugin
3. Press space and start typing to fuzzy search passwords
4. Select a password entry to see options:
   - **Copy Password**: Copy password to clipboard
   - **Type Password**: Type password using wtype
   - **Copy <field>**: Copy any field (username, URL, etc.)
   - **Type <field>**: Type any field using wtype

## Requirements

- [GNU Pass](https://www.passwordstore.org/) password store
- `wl-copy` for clipboard operations
- `wtype` for keyboard input (optional)

## Installation

1. Copy this plugin to your Noctalia plugins directory:
   ```
   ~/.config/noctalia/plugins/launcher-pass/
   ```

2. Enable the plugin in Noctalia settings

3. Configure a keybind for quick access (optional)

## Configuration

By default, the plugin uses `~/.password-store`. You can configure a custom path in the plugin settings.

## Keybinds

| Action | Description |
|--------|-------------|
| `>pass` | Open pass browser |
| `>pass <query>` | Search passwords |

## Fuzzy Search

Spaces are treated as wildcards. For example, searching `hom comp` will match:
- `/home/computer/`
- `/web/home/page/computing.gpg`
- `/homcomppass.gpg`

## License

MIT