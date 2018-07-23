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
      puts ttc.fonts[0].tables.keys
    end
  end
end

Emoji.run()
