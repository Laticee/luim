# Luim

A lightweight Vim clone written in Luau, running on the [Lune](https://lune-org.github.io/docs) runtime.

This is a pre-release and is currently unstable. Expect bugs, weird terminal behavior, and missing features. It's mostly a proof of concept for building terminal tools with Luau.

## The Story

Why Luau? 

It started in Roblox. I spent some time tinkering with Game Objects, DataStores, and complex game loops in Roblox Studio. Luau (Roblox's fork of Lua) became my second language (First is definitely Rust). I loved its speed, its type-checking, and how lightweight it felt.

But I wanted to build "real" tools. When I discovered Lune, which lets you run Luau anywhere, I knew what I had to do. I'm a Neovim guy. I live in the terminal. So, as a tribute to my roots and my favorite editor, I built Luim—a Vim clone that brings that Roblox-honed Luau power to the terminal.

## Startup Dashboard

When you launch Luim without a file, you're greeted with a minimalist dashboard. From there, you can:
- **f**: Find a file to open.
- **n**: Create a new file.
- **q**: Quit Luim.

## Features

- Fast: Written in Luau, optimized for the CI/CD and scriptable environments.
- Vim Keys: Support for h, j, k, l, i, x, dd, o, O, and more.
- File Explorer: Search and open files on the fly with Ctrl + P.
- Syntax Highlighting: Basic out-of-the-box highlighting for Luau files.
- Dynamic Resizing: Automatically adapts to your terminal window size.
- **Global Command**: Install Luim globally to use it anywhere.

## Installation

### Global Installation (Recommended)

To install Luim globally as the `luim` command:
```bash
chmod +x setup.sh
./setup.sh
```
This will compile the driver and create a wrapper in `/usr/local/bin`.

### Manual Run

1. Install Lune: Follow the instructions at [lune-org.github.io](https://lune-org.github.io/docs/installation).
2. Compile the Driver:
   ```bash
   lune run build.luau
   ```
3. Run Luim:
   ```bash
   lune run main.luau [optional_filename]
   ```

## Shortcuts

| Key | Mode | Action |
|-----|------|--------|
| i | NORMAL | Enter Insert Mode |
| Esc | INSERT | Return to Normal Mode |
| h/j/k/l | NORMAL | Move Cursor |
| x | NORMAL | Delete Character |
| dd | NORMAL | Delete Current Line |
| o | NORMAL | Insert New Line Below |
| O | NORMAL | Insert New Line Above |
| Ctrl + S | GLOBAL | Save Current File |
| Ctrl + P | GLOBAL | Open File Menu (Search) |
| Ctrl + Q | GLOBAL | Quit Luim |

## Architecture

- main.luau: The entry point, handling the main editor loop.
- src/core/buffer.luau: Manages text content, line splitting, and cursor clamping.
- src/ui/renderer.luau: Handles terminal drawing, ANSI escapes, and syntax highlighting.
- src/input/keyboard.luau: Bridges the C driver and Luau logic for responsive input.

---

*Made with heart and Luau.*
