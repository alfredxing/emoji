### Technical documentation

#### General architecture/steps
1. Parse `emoji-test.txt` and `additional.txt` to get a list of emoji code point combinations
2. Parse the `Apple Color Emoji.ttc` TrueType Collection into a list of TrueType fonts, and take the first one
3. Parse the necessary tables in the font
4. Map all Unicode code points to glyph IDs using data in the `cmap` table
5. Resolve ligatures into final glyph IDs using the state machines defined in the `morx` table
6. Map the final glyph IDs to image data with the `sbix` table
7. Write the image data to files on disk

The remainder of the documentation will focus on the font parsing aspect of the process, steps 2 through 6.

#### TrueType definitions and structure

#### Common Ruby patterns

#### `maxp`

#### `cmap`

#### `sbix`

#### `morx`
This is where it gets complicated. [LIGATURES.md](LIGATURES.md) documents the `morx` table, its subtables, and the
ligature processing algorithm using state machines.
