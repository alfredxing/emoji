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
        # NOTE: 3 esses because class is a reserved keyword -_-
        def classs
          return @classs if @classs
          return @classs = Lookup.parse(@bytes[@classTableOffset...@bytes.length])
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
        def component(i)
          return @component[i] if @component[i]

          start = @componentOffset + 2 * i
          @component[i] = @bytes[start, 2].unpack('n')[0]

          return @component[i]
        end

        # Ligature table
        # Each ligature is a UInt16 value
        def ligature(i)
          return @ligature[i] if @ligature[i]

          start = @ligatureOffset + 2 * i
          @ligature[i] = @bytes[start, 2].unpack('n')[0]

          return @ligature[i]
        end

        # Resolves a ligature, given the array of glyph IDs to process
        def resolve(glyphs)
          state = 1
          i = 0
          stack = []

          while i < glyphs.length
            glyph = glyphs[i]
            glyphClass = classs.map[glyph]

            return false if !glyph || !glyphClass

            entryIndex = state(state)[glyphClass]
            glyphEntry = entry(entryIndex)

            # Process flags
            entryFlags = glyphEntry[:entryFlags]

            # setComponent: push this glyph onto the component stack for eventual processing
            if (entryFlags & 0x8000) != 0
              stack.unshift(glyph)
            end

            # performAction: use the ligActionIndex to process a ligature group
            if (entryFlags & 0x2000) != 0
              actionIndex = glyphEntry[:ligActionIndex]
              lig = act(actionIndex, stack)
              return lig
            end

            # dontAdvance: leave the glyph pointer at this glyph for the next iteration
            unless (entryFlags & 0x4000) != 0
              i += 1
            end

            # Advance state
            state = glyphEntry[:nextStateIndex]

            # Guard for next state == 0 or 1
            if state == 0 || state == 1
              return false
            end
          end

          return false
        end

        # Run a ligature action for the given glyphs starting at the actionIndex
        def act(index, glyphs)
          acc = 0
          glyphs.each do |glyph|
            action = action(index)

            # Process component mask
            componentIndex = glyph + sign_extend(action & 0x3FFFFFFF, 30, 32)
            acc += component(componentIndex)

            if (action & 0x80000000 != 0) || (action & 0x40000000 != 0)
              # Store and return
              return ligature(acc)
            end

            index += 1
          end

          return false
        end

        # Signed extension to 32 bits
        def sign_extend(n, from, to)
          negative = (n & (1 << (from - 1))) != 0
          if negative
            # Sign extend, then 2's complement
            mask = ((1 << to) - 1) - ((1 << from) - 1)
            extended = n | mask
            inverse = ~(extended) & ((1 << to) - 1)
            complement = inverse + 1
            return -complement
          end

          return n
        end
      end
    end
  end
end
