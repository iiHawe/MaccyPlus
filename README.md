
<img width="128px" src="https://maccy.app/img/maccy/Logo.png" alt="Logo" />

# Maccy+

[![Downloads](https://img.shields.io/github/downloads/iiHawe/MaccyPlus/total.svg)](https://github.com/iiHawe/MaccyPlus/releases/latest)

Maccy+ is a fork of [Maccy](https://github.com/p0deje/Maccy) — a lightweight clipboard manager for macOS. It keeps the history of what you copy and lets you quickly navigate, search, and use previous clipboard contents.

Maccy+ adds power-user enhancements on top of the original:

- **Multi-select enabled by default** — select multiple history items at once using <kbd>SHIFT (⇧)</kbd> + <kbd>↑</kbd>/<kbd>↓</kbd> or <kbd>COMMAND (⌘)</kbd> + click
- **Unlimited history** — set history size to `0` in Preferences to keep an unlimited number of entries

Maccy+ works on macOS Sonoma 14 or higher.

<!-- vim-markdown-toc GFM -->

* [Features](#features)
* [Install](#install)
* [Usage](#usage)
* [Maccy+ Enhancements](#maccy-enhancements)
  * [Multi-Select](#multi-select)
  * [Unlimited History](#unlimited-history)
* [Advanced](#advanced)
  * [Ignore Copied Items](#ignore-copied-items)
  * [Ignore Custom Copy Types](#ignore-custom-copy-types)
  * [Speed up Clipboard Check Interval](#speed-up-clipboard-check-interval)
* [FAQ](#faq)
  * [Why doesn't it paste when I select an item in history?](#why-doesnt-it-paste-when-i-select-an-item-in-history)
  * [When assigning a hotkey to open Maccy+, it says that this hotkey is already used in some system setting.](#when-assigning-a-hotkey-to-open-maccy-it-says-that-this-hotkey-is-already-used-in-some-system-setting)
  * [How to restore hidden footer?](#how-to-restore-hidden-footer)
  * [How to ignore copies from Universal Clipboard?](#how-to-ignore-copies-from-universal-clipboard)
  * [My keyboard shortcut stopped working in password fields. How do I fix this?](#my-keyboard-shortcut-stopped-working-in-password-fields-how-do-i-fix-this)
* [Translations](#translations)
* [License](#license)

<!-- vim-markdown-toc -->

## Features

* Lightweight and fast
* Keyboard-first
* Secure and private
* Native UI
* Multi-select support (enabled by default)
* Unlimited clipboard history

## Install

Download the latest version from the [releases](https://github.com/iiHawe/MaccyPlus/releases/latest) page.

## Usage

1. <kbd>SHIFT (⇧)</kbd> + <kbd>COMMAND (⌘)</kbd> + <kbd>C</kbd> to popup Maccy+ or click on its icon in the menu bar.
2. Type what you want to find.
3. To select the history item you wish to copy, press <kbd>ENTER</kbd>, or click the item, or use <kbd>COMMAND (⌘)</kbd> + `n` shortcut.
4. To choose the history item and paste, press <kbd>OPTION (⌥)</kbd> + <kbd>ENTER</kbd>, or <kbd>OPTION (⌥)</kbd> + <kbd>CLICK</kbd> the item, or use <kbd>OPTION (⌥)</kbd> + `n` shortcut.
5. To choose the history item and paste without formatting, press <kbd>OPTION (⌥)</kbd> + <kbd>SHIFT (⇧)</kbd> + <kbd>ENTER</kbd>, or <kbd>OPTION (⌥)</kbd> + <kbd>SHIFT (⇧)</kbd> + <kbd>CLICK</kbd> the item, or use <kbd>OPTION (⌥)</kbd> + <kbd>SHIFT (⇧)</kbd> + `n` shortcut.
6. To delete the history item, press <kbd>OPTION (⌥)</kbd> + <kbd>DELETE (⌫)</kbd>.
7. To see the full text of the history item, wait a couple of seconds for tooltip.
8. To pin the history item so that it remains on top of the list, press <kbd>OPTION (⌥)</kbd> + <kbd>P</kbd>. The item will be moved to the top with a random but permanent keyboard shortcut. To unpin it, press <kbd>OPTION (⌥)</kbd> + <kbd>P</kbd> again.
9. To clear all unpinned items, select _Clear_ in the menu, or press <kbd>OPTION (⌥)</kbd> + <kbd>COMMAND (⌘)</kbd> + <kbd>DELETE (⌫)</kbd>. To clear all items including pinned, select _Clear_ in the menu with <kbd>OPTION (⌥)</kbd> pressed, or press <kbd>SHIFT (⇧)</kbd> + <kbd>OPTION (⌥)</kbd> + <kbd>COMMAND (⌘)</kbd> + <kbd>DELETE (⌫)</kbd>.
10. To disable Maccy+ and ignore new copies, click on the menu icon with <kbd>OPTION (⌥)</kbd> pressed.
11. To ignore only the next copy, click on the menu icon with <kbd>OPTION (⌥)</kbd> + <kbd>SHIFT (⇧)</kbd> pressed.
12. To customize the behavior, check "Preferences…" window, or press <kbd>COMMAND (⌘)</kbd> + <kbd>,</kbd>.

## Maccy+ Enhancements

### Multi-Select

Multi-select is enabled by default in Maccy+. You can select multiple clipboard history items and paste them all at once:

- **Range select:** Hold <kbd>SHIFT (⇧)</kbd> and press <kbd>↑</kbd> / <kbd>↓</kbd> to extend the selection
- **Individual select:** Hold <kbd>COMMAND (⌘)</kbd> and click items to toggle them in/out of the selection
- Press <kbd>ENTER</kbd> or <kbd>OPTION (⌥)</kbd> + <kbd>ENTER</kbd> to copy/paste all selected items

### Unlimited History

By default Maccy+ keeps a limited number of history entries. To store an unlimited number of items:

1. Open Preferences (<kbd>COMMAND (⌘)</kbd> + <kbd>,</kbd>).
2. Go to the **General** tab.
3. Set the **Size** field to `0`.

With size set to `0`, Maccy+ will never automatically remove old entries.

## Advanced

### Ignore Copied Items

You can tell Maccy+ to ignore all copied items:

```sh
defaults write com.hawe.MaccyPlus ignoreEvents true # default is false
```

This is useful if you have some workflow for copying sensitive data. You can set `ignoreEvents` to true, copy the data and set `ignoreEvents` back to false.

You can also click the menu icon with <kbd>OPTION (⌥)</kbd> pressed. To ignore only the next copy, click with <kbd>OPTION (⌥)</kbd> + <kbd>SHIFT (⇧)</kbd> pressed.

### Ignore Custom Copy Types

By default Maccy+ will ignore certain copy types that are considered to be confidential
or temporary. The default list always includes the following types:

* `org.nspasteboard.TransientType`
* `org.nspasteboard.ConcealedType`
* `org.nspasteboard.AutoGeneratedType`

Also, default configuration includes the following types but they can be removed
or overwritten:

* `com.agilebits.onepassword`
* `com.typeit4me.clipping`
* `de.petermaurer.TransientPasteboardType`
* `Pasteboard generator type`
* `net.antelle.keeweb`

You can add additional custom types using settings.
To find what custom types are used by an application, you can use
free application [Pasteboard-Viewer](https://github.com/sindresorhus/Pasteboard-Viewer).

### Speed up Clipboard Check Interval

By default, Maccy+ checks clipboard every 500 ms. To change it:

```sh
defaults write com.hawe.MaccyPlus clipboardCheckInterval 0.1 # 100 ms
```

## FAQ

### Why doesn't it paste when I select an item in history?

1. Make sure you have "Paste automatically" enabled in Preferences.
2. Make sure "Maccy+" is added to System Settings -> Privacy & Security -> Accessibility.

### When assigning a hotkey to open Maccy+, it says that this hotkey is already used in some system setting.

1. Open System settings -> Keyboard -> Keyboard Shortcuts.
2. Find where that hotkey is used. For example, "Convert text to simplified Chinese" is under Services -> Text.
3. Disable that hotkey or remove assigned combination.
4. Restart Maccy+.
5. Assign hotkey in Maccy+ settings.

### How to restore hidden footer?

1. Open Maccy+ window.
2. Press <kbd>COMMAND (⌘)</kbd> + <kbd>,</kbd> to open preferences.
3. Enable footer in Appearance section.

If for some reason it doesn't work, run the following command in Terminal.app:

```sh
defaults write com.hawe.MaccyPlus showFooter 1
```

### How to ignore copies from [Universal Clipboard](https://support.apple.com/en-us/102430)?

1. Open Preferences -> Ignore -> Pasteboard Types.
2. Add `com.apple.is-remote-clipboard`.

### My keyboard shortcut stopped working in password fields. How do I fix this?

If your shortcut produces a character (like `Option+C` → "ç"), macOS security may block it in password fields. Use [Karabiner-Elements](https://karabiner-elements.pqrs.org/) to remap your shortcut to a different combination like `Cmd+Shift+C`.

## Translations

Maccy+ inherits translations from the upstream [Maccy](https://github.com/p0deje/Maccy) project,
hosted on [Weblate](https://hosted.weblate.org/engage/maccy/).

## License

[MIT](./LICENSE)
