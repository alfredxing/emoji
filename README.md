## Apple Color Emoji image extraction

This script and library takes the Apple Color Emoji font file (found on macOS systems) and the Unicode emoji spec
test file as inputs, and extracts the bitmap image data for each emoji from the font at all available sizes. Of the
3377 emoji listed in the Emoji 5.0 test file, we're able to extract all 3356 supported by Apple emoji. The script
also allows additional codepoints to be specified in `data/additional.txt` for any emoji not listed in the test file
(e.g. standalone skin tones).

### Requirements & Dependencies
- macOS (latest version recommended)
- Ruby (latest version recommended)
- At least 500MB of free disk space 😛

### Running
````shell
# Clone the project
git clone https://github.com/alfredxing/emoji.git

# Copy the Apple emoji file to the repo directory
cp '/System/Library/Fonts/Apple Color Emoji.ttc' .

# Run the script
ruby emoji.rb
````

### Output
The script outputs images to the `img/` directory, which is then split into subdirectories, one for each size. Images
are in PNG format, and named as the sequence of corresponding Unicode code points, joined by a dash (`-`).

For example, the `👨‍👩‍👧‍👧 family: man, woman, girl, girl` emoji at size 64 would be located at
`img/64/1F468-200D-1F468-200D-1F467-200D-1F467.png`.

### Technical documentation
Documentation on how the code works can be found in [`DEVELOPMENT.md`](DEVELOPMENT.md).

### References
- Apple TrueType Reference Manual: https://developer.apple.com/fonts/TrueType-Reference-Manual/
- Cal's `emoji-data` project: https://github.com/iamcal/emoji-data
- The Unicode Emoji spec (currently supported version is Emoji 5.0): https://www.unicode.org/reports/tr51/tr51-12.html
  - This spec includes the source for the `data/emoji-test.txt` file: https://unicode.org/Public/emoji/5.0/emoji-test.txt
- The `Font::TTF` Perl module (in particular the [`AATUtils.pm`](https://metacpan.org/source/BHALLISSY/Font-TTF-1.06/lib/Font/TTF/AATutils.pm) file): https://metacpan.org/pod/Font::TTF
