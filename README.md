# Dew Transclude

🌿 **Dew Transclude** is a minimal, focused [Neorg](https://github.com/nvim-neorg/neorg) extension designed to enables automatic transclusion of note fragments based on in-file references.

This module is part of the [Neorg Dew](https://github.com/setupyourskills/neorg-dew) ecosystem.

## Features

- Parses inline transclusion syntax in `.norg` files.
- Automatically insert the extracted content blocks directly below the transclusion directives.
- Automatically delete the embedded content if the leading `!` before the link has been removed.
- Lightweight and easily customizable.

## Installation

### Prerequisites

- A functional installation of [Neorg](https://github.com/nvim-neorg/neorg) is required for this module to work.
- The core module [Neorg Dew](https://github.com/setupyourskills/neorg-dew) must be installed, as it provides essential base libraries.

### Using Lazy.nvim

```lua
{
  "setupyourskills/dew-transclude",
  ft = "norg",
  dependencies = {
    "setupyourskills/neorg-dew",
  },
}
```

## Configuration

Make sure all of them are loaded through Neorg’s module system in your config:

```lua
["external.neorg-dew"] = {},
["external.dew-transclude"] = {},
```

## Usage

Simply prefix the internal link with a `!` to embed the `.norg` file note in the current buffer:

```
!{path_to_the_note}[title of the note]
```

## How it works

1. Detects all transclusion directives matching the pattern `!{path_to_the_note}[title of the note]`

2. Adjusts the heading level to fit the current document structure.

3. Insert the content of the referrenced note into the current one

Each directive will be annotated in-place with the number of inserted lines, e.g.:

```lua
!{path_to_the_note}[title of the note]:> 7
```

4. Remove the embedded content if the leading `!` preceding the link is no longer present.

## Collaboration and Compatibility

This project embraces collaboration and may build on external modules created by other Neorg members, which will be tested regularly to ensure they remain **functional** and **compatible** with the latest versions of Neorg and Neovim.  

## Why **dew**?

Like morning dew, it’s **subtle**, **natural**, and brief, yet vital and effective for any workflow.
