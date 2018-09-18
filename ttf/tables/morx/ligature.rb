module Emoji
  module TTF
    module Tables
      # A `morx` ligature subtable
      class MORX::Chain::Subtable::Ligature < MORX::Chain::Subtable
        attr_reader :nClasses, :ligatureOffset

        def initialize(**args)
          super(**args)

          extended()

          # Memoization maps
          @state = {}
          @entry = {}
          @action = {}
          @component = {}
          @ligature = {}
        end

        # Extended state table header and ligature table offsets
        #
        # Offset    Type        Name
        # 0         UInt32      nClasses
        # 4         UInt32      classTableOffset
        # 8         UInt32      stateArrayOffset
        # 12        UInt32      entryTableOffset
        # 16        UInt32      ligActionOffset
        # 20        UInt32      componentOffset
        # 24        UInt32      ligatureOffset
        def extended
          @nClasses, @classTableOffset, @stateArrayOffset, @entryTableOffset = @bytes[0, 16].unpack('NNNN')
          @ligActionOffset, @componentOffset, @ligatureOffset = @bytes[16, 12].unpack('NNN')
        end

        # Class lookup table
        def class
          return Lookup.parse(@bytes[@classTableOffset...@bytes.length])
        end

        # State array
        # 2D array of UInt16, mapping [state, class] to an index into the entry subtable
        def state(i)
          return @state[i] if @state[i]

          # Row size is 2 bytes times number of classes
          rowSize = 2 * @nClasses
          start = @stateArrayOffset + rowSize * i
          @state[i] = @bytes[start, rowSize].unpack('n*')

          return @state[i]
        end

        # Entry table
        #
        # Offset    Type        Name
        # 0         UInt16      nextStateIndex
        # 2         UInt16      entryFlags
        # 4         UInt16      ligActionIndex
        def entry(i)
          return @entry[i] if @entry[i]

          start = @entryTableOffset + 6 * i
          nextStateIndex, entryFlags, ligActionIndex = @bytes[start, 6].unpack('nnn')

          @entry[i] = {
            :nextStateIndex => nextStateIndex,
            :entryFlags => entryFlags,
            :ligActionIndex => ligActionIndex,
          }

          return @entry[i]
        end

        # Ligature action table
        # Each action is just a UInt32 value
        def action(i)
          return @action[i] if @action[i]

          start = @ligActionOffset + 4 * i
          @action[i] = @bytes[start, 4].unpack('N')[0]

          return @action[i]
        end

        # Component table
        # Each component is a UInt16 value
        def component
          return @component[i] if @component[i]

          start = @componentOffset + 2 * i
          @component[i] = @bytes[start, 2].unpack('n')[0]

          return @component[i]
        end

        # Ligature table
        # Each ligature is a UInt16 value
        def ligature
          return @ligature[i] if @ligature[i]

          start = @ligatureOffset + 2 * i
          @ligature[i] = @bytes[start, 2].unpack('n')[0]

          return @ligature[i]
        end
      end
    end
  end
end
