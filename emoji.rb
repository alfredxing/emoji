require 'fileutils'
require 'json'

require_relative 'ttf/ttf'
require_relative 'ttf/ttc'

# Reads, writes, and processes any data not related to the font format
# itself; namely, the font file and image data
module Emoji
  class << self
    def read
      f = File.open('Apple Color Emoji.ttc', 'rb')
      f.read
    end

    def run
      file = read()
      data = parse_data()

      puts "Parsed data: #{data.length} emoji"

      # Process TTC container
      ttc = TTF::TTC.new(file)
      font = ttc.fonts[0]
      numGlyphs = font.tables['maxp'].numGlyphs
      reverse = font.tables['cmap'].reverse(numGlyphs)

      data.each do |input|
        cps = input.split('-').map { |hex| hex.to_i(16) }
        glyphs = cps.map { |uni| reverse[uni] }

        if glyphs.length > 1
          lig = font.tables['morx'].chains[0].subtables
            .map { |s|
              next if s == nil
              s.resolve(glyphs)
            }
            .find { |lig| lig }
        else
          lig = glyphs[0]
        end

        begin
          # I hate special cases, but for some reason the font doesn't have
          # single fully-qualified codepoints made up of the non-fully-qualified
          # one followed by FE0F (variation selector), so if we detect this
          # is the case, just use the non-fully-qualified code point.
          #
          # TODO: figure out if the font actually handles this and how?
          if !lig && cps.length == 2 && cps[1] == 0xFE0F
            lig = glyphs[0]
          end

          font.tables['sbix'].strikes.each do |strike|
            size = strike.ppem
            glyph = strike.glyphs[lig]
            raise StandardError, 'Glyph data empty' if glyph.data.length == 0

            FileUtils.mkdir_p("img/#{size}")
            File.open("img/#{size}/#{input}.png", 'wb') do |f|
              f.write(glyph.data)
            end
          end
        rescue
          puts "Can't find image for combination #{input} with error #{$!}"
        end
      end
    end

    def parse_data
      raw = File.open('data/emoji-test.txt', 'r').read
      return raw.lines
        .map do |row|
          match = row.match(/^[0-9a-f]+(\s[0-9a-f]+)*/i)

          if match
            match[0].gsub(/\s+/, '-')
          else
            nil
          end
        end
        .select { |row| row }
    end
  end
end

Emoji.run()
