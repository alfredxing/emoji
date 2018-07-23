module Emoji
  module TTF
    module Tables
      # `maxp` table
      # Memory requirements for the font; in particular we are interested in `numGlyphs`
      #
      # Offset    Type        Name
      # 0         Fixed       version (unused)
      # 2         UInt16      numGlyphs
      class MAXP
        attr_reader :numGlyphs

        def initialize(raw)
          @bytes = raw

          @version = @bytes[0, 4]
          @numGlyphs = @bytes[4, 2].unpack('n')[0]
        end
      end
    end
  end
end
