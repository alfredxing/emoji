module Emoji
  module TTF
    module Tables
      # `sbix` table
      # Contains image bitmaps (emoji image data)
      class SBIX
        def initialize(raw, numGlyphs)
          @bytes = raw
          @numGlyphs = numGlyphs

          header()
          strikes()
        end

        # Table header
        #
        # Offset    Type        Name
        # 0         UInt16      version
        # 2         UInt16      flags (unused)
        # 4         UInt32      numStrikes
        # 8         UInt32[]    strikeOffset[numStrikes]
        def header
          @version, @flags, @numStrikes = @bytes[0, 8].unpack('nnN')

          @strikeOffset = (0...@numStrikes).map do |n|
            start = 8 + n * 4
            @bytes[start, 4].unpack('N')[0]
          end
        end

        # Strike data records
        #
        # Offset    Type        Name
        # 0         UInt16      ppem
        # 2         UInt16      resolution (unused)
        # 4         UInt32[]    glyphDataOffset[numGlyphs + 1]
        def strikes
          if @strikes then
            return @strikes
          end

          @strikes = @strikeOffset.map do |offset|
            # Process metadata
            ppem, resolution = @bytes[offset, 4].unpack('nn')
            glyphDataOffset = (0...(@numGlyphs + 1)).map do |n|
              @bytes[offset + 4 + (n * 4), 4].unpack('N')[0]
            end

            # Retrieve glyphs
            glyphs = (0...@numGlyphs).map do |glyphID|
              # Each glyph starts at the specified offset and ends
              # at the next glyph's offset
              start = glyphDataOffset[glyphID]
              length = glyphDataOffset[glyphID + 1] - start

              if length == 0 then
                nil
              else
                Glyph.new(@bytes[offset + start, length])
              end
            end

            Strike.new(
              ppem: ppem,
              resolution: resolution,
              glyphDataOffset: glyphDataOffset,
              glyphs: glyphs,
            )
          end
        end
      end

      class SBIX::Strike
        attr_reader :ppem, :resolution, :glyphDataOffset, :glyphs

        def initialize(ppem:, resolution: nil, glyphDataOffset: nil, glyphs:)
          @ppem = ppem
          @resolution = resolution
          @glyphDataOffset = glyphDataOffset
          @glyphs = glyphs
        end
      end

      # Glyph bitmap
      #
      # Offset    Type        Name
      # 0         SInt16      originOffsetX
      # 2         SInt16      originOffsetY
      # 4         Tag         graphicType
      # 8         UInt8[]     data[]
      class SBIX::Glyph
        attr_reader :originOffsetX, :originOffsetY, :graphicType, :data

        def initialize(bytes)
          @bytes = bytes

          @originOffsetX, @originOffsetY = @bytes[0, 4].unpack('s>s>')
          @graphicType = @bytes[4, 4]
          @data = @bytes[8, @bytes.length - 8]
        end
      end
    end
  end
end
