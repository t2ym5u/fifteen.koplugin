# Changelog

All notable changes to this project will be documented in this file.

Reconstructed from this repository's git history: each release lists the
feature and fix commits it carried. Version bumps, screenshot additions
and CI syncs are left out.

## [1.2.3] - 2026-11-03

### Changed
- Picks up game-common 1.11.0: the shared on-screen keyboard (where used)
  gives every key the same letter size, and the no-repeat history helper.

## [1.2.2] - 2026-11-02

### Changed
- Picks up game-common 1.10.0: the shared Tools → Games menu also lists
  the games' new "· multiplayer" entries under Party & quiz.

## [1.2.1] - 2026-11-02

### Changed
- Listed under **Tools → Games**, grouped by category, instead of its own
  entry in the Tools menu (game-common 1.9.1).

## [1.2.0] - 2026-10-30

### Changed
- Redesigned play screen: the board fills the room the status line leaves,
  with one edge around it. Once the picture is reassembled, a "New game" bar
  appears under the status.
- The status line reads "4×4 · Moves: 12 · Time: 1:05 · Best: 80" (Best only
  once there is one, instead of "-") and wraps in landscape.
- The size entry in the title-bar menu reads "Size: 4×4" instead of a bare
  "4×4".

### Fixed
- Tile numbers were scaled by DPI twice and overflowed their tiles on high-DPI
  screens; they are now fitted to them.

## [1.1.19] - 2026-10-07

### Fixed
- The Tools menu entry is translated again. `main.lua` took `_` from
  KOReader's `gettext`, which knows nothing of this plugin's strings, so the
  menu label stayed English while the game's own screen, which goes through
  `i18n`, was translated. `_` now comes from `i18n` here too.


## [1.1.18] - 2026-10-01

### Fixed
- Picks up game-common v1.5.0. Play statistics were recorded under a key no
  tool could match: `ReaderUI`/`FileManager:registerModule()` rewrite a plugin
  instance's `name` to `reader<id>` / `filemanager<id>` right after it is
  built, so this game's sessions were split across two rows and neither
  carried its plugin id. Rows written under the old keys are merged back on
  first read. The same release brings the `stopPlugin()` /
  `deletePluginSettings()` hooks KOReader 2026.07 calls when a plugin is
  deleted from the device (PR #15240).

  No change to this plugin's own code -- it inherits all of it from the
  shared library.

## [1.1.17] - 2026-08-05

### Added
- Add ES and DE translations

### Changed
- Add screenshot to README
- Add issue/PR templates and CONTRIBUTING.md

## [1.1.16] - 2026-08-04

### Changed
- Symlink common/ to shared game-common

## [1.1.13] - 2026-07-29

### Fixed
- Drop deprecated name field from _meta.lua

## [1.1.10] - 2026-07-28

### Added
- Replace placeholder icons with real grayscale photographs

### Changed
- Add GPL-3.0 LICENSE

## [1.1.7] - 2026-07-21

### Added
- Own translations locally instead of via game-common

## [1.1.5] - 2026-07-15

### Added
- Add picture mode (slice a bundled image across the tiles)
- Adopt TitleBar header, sync common/ with game-common

## [1.1.4] - 2026-07-13

### Fixed
- OnCellTap gesture arg was nil (crash on tap) (v1.1.4)

## [1.1.3] - 2026-07-10

### Fixed
- Wire cellTapCallback/cellHoldCallback in screen (broke after rename)

## [1.1.2] - 2026-07-10

### Changed
- Remove ../game-common/ fallback from package.path

### Fixed
- Gesture tap detection (GestureRange range function)

## [1.1.1] - 2026-07-10

### Changed
- Rename onCellTap/onCellHold → cellTapCallback/cellHoldCallback + v1.1.1

## [1.1.0] - 2026-07-08

### Added
- I18n FR/EN translation + bump to 1.1.0

## [1.0.1] - 2026-07-07

### Fixed
- Correct text vertical centering in board widget
