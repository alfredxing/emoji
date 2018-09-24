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

#### Classes

Because there are a large number of possible sequences of emoji forming ligatures, it's inefficient to have unique transitions per glyph; instead, similar sets of glyphs are grouped into "classes" before being processed again. In the state machine representation in the font, all transitions are done through these classes (even if they sometimes only contain a single glyph).

### Representation in the font (the `morx` table) [[reference]](https://developer.apple.com/fonts/TrueType-Reference-Manual/RM06/Chap6morx.html)

The `morx` table is split up into chains (in the current Apple Emoji font, there is only 1 chain to process), which is then split into the feature subtables (unused here) and actual subtables; of those, we are interested in the ligature subtables (type 2).

Each ligature subtable stores the representation of a state machine, which comprises the following tables (whose offsets are given by the subtable header):

- **Class table**: maps glyph IDs to classes
- **State array**: maps a given state and class to the index of the corresponding item in the entry table
- **Entry table**: contains information about the next state to transition to, and any actions that need to be taken
- **Ligature action table**: information on what action to take if specified by the entry table
- **Component table**: contains values that are accumulated and added up as the ligature is processed; the added result is then used as an index into the ligature table
- **Ligature table**: maps component results to the glyph ID of the final ligature

#### Class lookup tables [[reference]](https://developer.apple.com/fonts/TrueType-Reference-Manual/RM06/Chap6Tables.html#LookupTables)

Class lookup tables map glyph IDs to the classes used to determine which transition to take. There are a few formats of lookup tables, 3 of which are used in the Apple Emoji font:

- **Segment Array (Format 4)**: an array of segments covering `[startGlyph, endGlyph]` and mapping them to their respective classes in an array
- **Single Table (Format 6)**: an array of classes indexed directly by glyph ID
- **Trimmed Array (Format 8)**: similar to the single table, but the first item in the array maps from `firstGlyph` instead of 0

#### State array

The state array is a 2D array with the state ID as the row index, and the class as the column index. For example, if we are currently at state 5 and the next glyph has class 11, the value we would read is `stateArray[5][11]`. The 2D array is stored in row-major order. The value read is the index into the entry table.

#### Entry table

The entry table is an array of state entries, containing the next state to transition to as well as flags to determine whether additional actions need to be taken:

- `setComponent` (`0x8000`) &mdash; Push the current glyph onto a stack (the "component stack") for processing later on
- `dontAdvance` (`0x4000`) &mdash; Go to the next state, but not the next glyph
- `performAction` (`0x2000`) &mdash; Process the stored component stack into a ligature using the instructions in the ligature action table _starting_ at index `ligActionIndex`

#### Ligature action table

The ligature action contains instructions for processing a component stack (list of glyph IDs).

> ⚠️ *Note*: The index into the action table is the _starting_ index of the instructions. If the component stack has 5 glyphs, the instructions are the 5 actions starting from the given index.

Each action contains couple of flags in addition to an `offset` field which is used to pre-process the glyph ID. The algorithm to run through the actions is:

1. Initialize the component accumulator to 0
2. Iterate through the component stack. For each glyph ID, and its corresponding action:
    1. Compute the offset (`action & 0x3FFFFFFF`, then sign extend to 32 bits)
    2. Add the offset to the glyph ID
    3. Use the result to the index into the component table to get the component value
    4. Add the component value to the component accumulator
    5. If the action has either the `last` or `store` flags, break the loop
3. Use the value of the component accumulator to index into the ligature table to get the final glyph ID

#### Component table

The component table is a simple array mapping the offseted glyph ID to component value.

#### Ligature table

The ligature table is an array that maps component accumulator sums to ligature glyph IDs.

## A simple example with real tables

Let's use 🤷🏽 (`person shrugging: medium skin tone`) as an example, which is made up of code points `U+1F937 U+1F3FD`, and assume the `cmap` table tells us these are glyph IDs `2174` and `879`, respectively. We'll lay out the tables, then run through the algorithm.

#### Class lookup table:
| Name | Value | Description |
|---|---|---|
| `format` | `4` | Format 4 (segment array) lookup table |
| `binSrchHeader.unitSize` | `6` | _Not used_ (used for binary searching the class table) |
| `binSrchHeader.nUnits` | `2` | The number of segments that follow |
| `binSrchHeader.searchRange` | `12` | _Not used_ |
| `binSrchHeader.entrySelector` | `1` | _Not used_ |
| `binSrchHeader.rangeShift` | `0` | _Not used_ |
| `segments[0].lastGlyph` | `2174` | Last glyph of segment 0 is the Person Shrugging glyph |
| `segments[0].firstGlyph` | `1881` | First glyph of segment 0 is the Person Frowning glyph |
| `segments[0].value` | `24` | Start of the values array for segment 0 is at offset 14 |
| `segments[1].lastGlyph` | `881` | Last glyph of segment 0 is the dark skin tone modifier |
| `segments[1].firstGlyph` | `877` | First glyph of segment 0 is the light skin tone modifier |
| `segments[1].value` | `610` | Start of the values array for segment 1 is at offset 600 |
| `segments[0].values` | `[3, 3, ..., 3]` | All glyphs from 1881 to 2174 have class 3 |
| `segments[1].values` | `[5, 5, 5, 5]` | All skin tone modifiers have class 5 |

#### State array:
| | Class 0 | Class 1 | Class 2 | Class 3 | Class 4 | Class 5 |
|---|---|---|---|---|---|---|
| **State 0** | 0 | 6 | 5 | 0 | 0 | 0 |
| **State 1** | 0 | 4 | 0 | 1 | 4 | 0 |
| **State 2** | 13 | 12 | 0 | 0 | 3 | 2 |
