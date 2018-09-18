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

        FileUtils.mkdir_p('img/160')
        File.open("img/160/#{input}.png", 'wb') do |f|
          begin
            glyph = font.tables['sbix'].strikes[8].glyphs[lig]
            f.write(glyph.data)
          rescue
            puts "Can't find image for combination #{input}"
          end
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
