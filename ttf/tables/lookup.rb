module Emoji
  module TTF
    module Tables
      # A special lookup table
      #
      # Offset    Type        Name
      # 0         UInt16      format
      class Lookup
        attr_reader :format

        def initialize(raw)
          @bytes = raw

          header()
        end

        def header
          @format = @bytes[0, 2].unpack('n')[0]
        end

        class << self
          def parse(raw)
            generic = Lookup.new(raw)
            case generic.format
            when 4
              SegmentArray.new(raw)
            when 6
              SingleTable.new(raw)
            when 8
              TrimmedArray.new(raw)
            else
              raise NotImplemented
            end
          end
        end
      end

      # Segment Array (Format 4) Lookup Table
      #
      # Offset    Type                 Name
      # 0         UInt16               format
      # 2         BinarySearchHeader   binSrchHeader
      # 12        LookupSegment[]      segments
      class Lookup::SegmentArray < Lookup
        attr_reader :binSrchHeader, :map

        def initialize(raw)
          super(raw)

          fs_header()
          segments()
        end

        def fs_header
          @binSrchHeader = BinarySearchHeader.new(@bytes[2, 10])
        end

        # Process segments
        #
        # Offset    Type        Name
        # 0         UInt16      lastGlyph
        # 2         UInt16      firstGlyph
        # 4         UInt16      value
        def segments
          return @segments if @segments

          @map = {}
          @segments = [*0...@binSrchHeader.nUnits].map do |n|
            start = 12 + n * 6
            lastGlyph, firstGlyph, value = @bytes[start, 6].unpack('nnn')

            # NOTE: value size 2 (UInt16) is hardcoded, as it is the only
            # size used by the `morx` class table
            values = @bytes[value, (lastGlyph - firstGlyph + 1) * 2].unpack('n*')

            [*firstGlyph..lastGlyph].each_with_index do |glyph, i|
              @map[glyph] = values[i] unless values[i] == 0
            end

            Segment.new({
              :lastGlyph => lastGlyph,
              :firstGlyph => firstGlyph,
              :values => values,
            })
          end
        end
      end

      # A single format 4 segment
      class Lookup::SegmentArray::Segment
        attr_reader :lastGlyph, :firstGlyph, :values

        def initialize(lastGlyph:, firstGlyph:, values:)
          @lastGlyph, @firstGlyph, @values = [lastGlyph, firstGlyph, values]
        end
      end

      # Single Table (Format 6) Lookup Table
      #
      # Offset    Type                 Name
      # 0         UInt16               format
      # 2         BinarySearchHeader   binSrchHeader
      # 12        LookupSingle[]       entries
      class Lookup::SingleTable < Lookup
        attr_reader :binSrchHeader, :map

        def initialize(raw)
          super(raw)

          fs_header()
          entries()
        end

        def fs_header
          @binSrchHeader = BinarySearchHeader.new(@bytes[2, 10])
        end

        # Process entries
        #
        # Offset    Type        Name
        # 0         UInt16      glyph
        # 2         UInt16      value
        def entries
          return @entries if @entries

          @map = {}
          @segments = [*0...@binSrchHeader.nUnits].map do |n|
            start = 12 + n * 4
            glyph, value = @bytes[start, 4].unpack('nn')

            @map[glyph] = value
          end

          @map
        end
      end

      # Trimmed Array (Format 8) Lookup Table
      #
      # Offset    Type        Name
      # 0         UInt16      format
      # 2         UInt16      firstGlyph
      # 4         UInt16      glyphCount
      # 6         UInt16[]    valueArray
      class Lookup::TrimmedArray < Lookup
        attr_reader :map

        def initialize(raw)
          super(raw)

          header()
          values()
        end

        def header
          @firstGlyph, @glyphCount = @bytes[2, 4].unpack('nn')
        end

        def values
          @map = {}

          [*0...@glyphCount].map do |n|
            start = 6 + n * 2
            glyph = @firstGlyph + n
            value = @bytes[start, 2].unpack('n')[0]

            @map[glyph] = value
          end
        end
      end

      # Binary Search table header
      #
      # Offset    Type        Name
      # 0         UInt16      unitSize
      # 2         UInt16      nUnits
      # 4         UInt16      searchRange
      # 6         UInt16      entrySelector
      # 8         UInt16      rangeShift
      class Lookup::BinarySearchHeader
        attr_reader :unitSize, :nUnits, :searchRange, :entrySelector, :rangeShift

        def initialize(raw)
          @bytes = raw

          header()
        end

        def header
          @unitSize, @nUnits, @searchRange, @entrySelector, @rangeShift = @bytes[0, 10].unpack('nnnnn')
        end
      end

      class Lookup::NotImplemented < StandardError
      end
    end
  end
end
