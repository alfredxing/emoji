## Technical documentation

### General architecture/steps
1. Parse `emoji-test.txt` and `additional.txt` to get a list of emoji code point combinations
2. Parse the `Apple Color Emoji.ttc` TrueType Collection into a list of TrueType fonts, and take the first one
3. Parse the necessary tables in the font
4. Map all Unicode code points to glyph IDs using data in the `cmap` table
5. Resolve ligatures into final glyph IDs using the state machines defined in the `morx` table
6. Map the final glyph IDs to image data with the `sbix` table
7. Write the image data to files on disk

The remainder of the documentation will focus on the font parsing aspect of the process, steps 2 through 6.

### TrueType definitions and structure [[reference]](https://developer.apple.com/fonts/TrueType-Reference-Manual/RM06/Chap6.html)

TrueType fonts and collections are binary files with values (usually unsigned integers or ASCII text) arranged in tables and subtables, concatentated together with no separators in the file (instead, their sizes/offsets defined in the specification or elsewhere in the font).

#### Data types

| Name | Description |
|---|---|
| `UInt16` | Unsigned 16-bit integer |
| `UInt32` | Unsigned 32-bit integer |
| `Tag` | 4-byte ASCII code |

#### TrueType Collections [[reference]](https://docs.microsoft.com/en-us/typography/opentype/spec/otff#ttc-header)

The Apple Color Emoji font file is a TrueType collection, which is a container for multiple fonts, though for image extraction we'll only need the first one. The collection starts with a 4-byte tag containing `ttcf` (`7474 6366` in hex), followed by version numbers and an array of offsets to the start of each contained font.

#### TrueType font format

Each font begins with the offset subtable, which specifies some metadata such as the type of the font, the number of subtables, and the table directory, which lists the rest of the tables in the font along with their offsets and lengths.

> ⚠️ *Note*: In a TTC, the offset of each table is specified as the offset from the start of the file, not from the start of each font.

### Common Ruby patterns

### TrueType tables

#### `maxp`

#### `cmap`

#### `sbix`

#### `morx`
This is where it gets complicated. [LIGATURES.md](LIGATURES.md) documents the `morx` table, its subtables, and the
ligature processing algorithm using state machines.
