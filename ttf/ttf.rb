require_relative 'tables/cmap'
require_relative 'tables/maxp'
require_relative 'tables/name'
require_relative 'tables/sbix'

module Emoji
  module TTF
    # Processes the TTF (TrueType) font format.
    # A TTC file is a collection of tables, the first of which is the
    # font/table directory.
    class TTF
      def initialize(bytes, offset)
        @bytes = bytes
        @fontOffset = offset

        header()
        tables()
      end

      # TTF header (offset table)
      #
      # Offset    Type        Name
      # 0         UInt32      sfntVersion
      # 4         UInt16      numTables
      # 6         UInt16      searchRange (unused)
      # 8         UInt16      entrySelector (unused)
      # 10        UInt16      rangeShift (unused)
      def header
        @sfntVersion, @numTables, *rest = @bytes[0, 4 + 2 + 2 + 2 + 2].unpack('Nnnnn')
      end

      # Table directory
      # (Offset 12 bytes from start of font)
      #
      # Offset    Type        Name
      # 0         Tag         tag
      # 4         UInt32      checkSum (unused)
      # 8         UInt32      offset
      # 12        UInt32      length
      def tables
        if @tables then
          return @tables
        end

        @tables = {}

        @numTables.times do |n|
          # Directory is offset by 12 bytes; each entry is 16 bytes
          start = 12 + n * 16

          tag = @bytes[start, 4]
          checkSum, offset, length = @bytes[start + 4, 12].unpack('NNN')

          raw = @bytes[offset - @fontOffset, length]

          case tag
          when 'cmap'
            @tables[tag] = Tables::CMAP.new(raw)
          when 'maxp'
            @tables[tag] = Tables::MAXP.new(raw)
          when 'name'
            @tables[tag] = Tables::NAME.new(raw)
          when 'sbix'
            @tables[tag] = Tables::SBIX.new(raw, @tables['maxp'].numGlyphs)
          else
            @tables[tag] = nil
          end
        end
      end
    end
  end
end
