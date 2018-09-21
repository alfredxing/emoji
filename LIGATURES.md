## Ligatures processing for emoji sequences and modifiers

Emoji such as 👨‍👩‍👧‍👧 or 🇨🇦, or emoji with skin tones such as 👩🏾‍💻, use a combination of multiple Unicode code points to form a single glyph. To achieve this in the font, Apple Emoji uses ligatures, with data stored in the `morx` table (which is specific to the Apple Advanced Typography spec)

### A quick intro

Ligatures transform multiple glyphs into another single glyph. This glyph may not map back to any specific Unicode code point, but it may index into the `sbix` table to give us the image we need.

For example, with the `family: man, woman, girl, girl` emoji 👨‍👩‍👧‍👧:
1. The Unicode code point sequence used to construct the emoji is `1F468 200D 1F469 200D 1F467 200D 1F467`
2. The corresponding glyph IDs are `1062, 43, 1164, 43, 1056, 43, 1056`
3. These glyph IDs are transformed through the ligature process into a single glyph ID, `1280`
4. The glyph `1280` maps to the image you see above in the `sbix` table

### State tables and state machines [[reference]](https://developer.apple.com/fonts/TrueType-Reference-Manual/RM06/Chap6Tables.html#StateTables)

#### A simplified example

The font uses state tables to represent a finite state machines, which is what processes sequences of glyphs into another glyph as a ligature.

Consider the Canadian flag emoji 🇨🇦. It's constructed from a sequence of 2 glyphs, the regional indicator C glyph and regional indicator A glyph (we'll refer to them as `C` and `A` throughout this doc, though they're actually `🇨` and `🇦`).

The state machine begins at a `START` state, then transitions to a new `SEEN-C` state when it sees `C`, and from there, resolves the ligature if it sees `A` as the next glyph.

<img src="https://user-images.githubusercontent.com/2704010/45908067-7e424980-bdaf-11e8-96bd-77fc07477d0b.png" width="400">
