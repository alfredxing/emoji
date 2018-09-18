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
      @contents = f.read
    end

    def run
      read()

      # Process TTC container
      ttc = TTF::TTC.new(@contents)
      font = ttc.fonts[0]
      numGlyphs = font.tables['maxp'].numGlyphs
      reverse = font.tables['cmap'].reverse(numGlyphs)

      input = '1F469'
      cps = input.split('-').map { |hex| hex.to_i(16) }
      glyphs = cps.map { |uni| reverse[uni] }

      lig = font.tables['morx'].chains[0].subtables
        .map { |s|
          next if s == nil
          s.resolve(glyphs)
        }
        .find { |lig| lig }

      FileUtils.mkdir_p('img/lig')
      File.open("img/lig/#{input}.png", 'wb') do |f|
        glyph = font.tables['sbix'].strikes[8].glyphs[lig]
        f.write(glyph.data)
      end
    end
  end
end

Emoji.run()
