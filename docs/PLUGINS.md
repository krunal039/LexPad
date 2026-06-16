# LexPad Plugins

LexPad supports **script-based plugins** — shell scripts that transform the selected text (or whole document) and return output.

## Built-in plugins

These ship with LexPad (no install needed):

- JSON Formatter
- XML Formatter
- CSV Lint

Enable them in **Settings → Plugins** or **Tools → Plugin Manager…**, then run from **Tools → Plugins**.

## Add your own plugin

### 1. Open the plugins folder

**Settings → Plugins → Open Plugins Folder**

Or **Tools → Plugin Manager… → Open Plugins Folder**

Default location:

```
~/Library/Application Support/LexPad/Plugins/
```

### 2. Create a plugin folder

```
Plugins/
  my-sort-plugin/
    plugin.json
    plugin.sh
```

### 3. Add plugin.json

```json
{
  "id": "com.example.sort-lines",
  "name": "Sort Lines",
  "version": "1.0.0",
  "description": "Sorts selected lines A–Z",
  "entryPoint": "plugin.sh",
  "script": "plugin.sh",
  "author": "Your Name"
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `id` | Yes | Unique ID (reverse-DNS style) |
| `name` | Yes | Display name |
| `version` | Yes | Semver string |
| `description` | Yes | Short summary |
| `entryPoint` | Yes | Script filename |
| `script` | Yes | Same as entryPoint for shell plugins |
| `author` | No | Your name |

### 4. Add plugin.sh

The script receives selected text (or full document) on **stdin** and writes transformed text to **stdout**.

Example `plugin.sh`:

```bash
#!/bin/bash
sort
```

Make it executable:

```bash
chmod +x plugin.sh
```

### 5. Rescan and enable

1. Click **Rescan** in Settings → Plugins
2. Toggle the plugin **ON**
3. Run from **Tools → Plugins → Your Plugin Name**

## How plugins work

- LexPad passes the current selection (or entire file if nothing selected) to your script via stdin
- Script output replaces the selection, or the whole document if nothing was selected
- Plugins appear in **Tools → Plugins** when enabled

## Troubleshooting

- Script must be executable (`chmod +x`)
- Check `plugin.json` is valid JSON with all required fields
- Click **Rescan** after adding files
- Plugin must be **enabled** in Settings → Plugins
