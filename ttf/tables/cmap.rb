module Emoji
  module TTF
    module Tables
      # `cmap` table
      # Mapping of character codes (code points) to glyph IDs
      class CMAP
        def initialize(raw)
          @bytes = raw

          header()
          tables()
        end

        # Table header
        #
        # Offset    Type        Name
        # 0         UInt16      version (unused)
        # 2         UInt16      numTables
        def header
          @version = @bytes[0, 2]
          @numTables = @bytes[2, 2].unpack('n')[0]
        end

        # `cmap` subtable records
        # (Offset 4 bytes from start of table)
        #
        # Offset    Type        Name
        # 0         UInt16      platformID
        # 2         UInt16      platformSpecificID
        # 4         UInt32      offset
        def tables
          if @tables then
            return @tables
          end

          @tables = [*0...@numTables].map do |n|
            start = 4 + n * 8
            platformID, platformSpecificID, offset = @bytes[start, 8].unpack('nnN')

            # Only support cmap 0/4
            if platformID != 0 || platformSpecificID != 4 then
              nil
            end

            begin
              Segmented.new(@bytes[offset...@bytes.length])
            rescue NotImplemented
              nil
            end
          end
        end

        # Given numGlyphs, fill in an index of glyph ID to (unicode) charCode
        def map(numGlyphs)
          mapping = [*0...numGlyphs].map { 0 }

          @tables.each do |table|
            table.groups.each do |group|
              mapping[group.startGlyphCode, group.length] = [*group.startCharCode..group.endCharCode]
            end
          end

          return mapping
        end
      end

      # Processes format 12 (segemented coverage) subtables
      class CMAP::Segmented
        attr_reader :groups

        def initialize(bytes)
          @bytes = bytes

          header()
          groups()
        end

        # Subtable header
        #
        # Offset    Type        Name
        # 0         UInt16      format (set to 12)
        # 2         UInt16      reserved (unused)
        # 4         UInt32      length (unused)
        # 8         UInt32      language (unused)
        # 12        UInt32      numGroups
        def header
          format = @bytes[0, 2].unpack('n')[0]
          if format != 12 then
            raise NotImplemented
          end

          @numGroups = @bytes[12, 4].unpack('N')[0]
        end

        # Process groups
        # (Offset 16 bytes from beginning of subtable)
        #
        # Offset    Type        Name
        # 0         UInt32      startCharCode
        # 4         UInt32      endCharCode
        # 8         UInt32      startGlyphCode
        def groups
          if @groups then
            return @groups
          end

          @groups = [*0...@numGroups].map do |n|
            start = 16 + n * 12
            startCharCode, endCharCode, startGlyphCode = @bytes[start, 12].unpack('NNN')

            Group.new({
              :startCharCode => startCharCode,
              :endCharCode => endCharCode,
              :startGlyphCode => startGlyphCode,
            })
          end
        end
      end

      # Represents a single format 12 group record
      class CMAP::Segmented::Group
        attr_reader :startCharCode, :endCharCode, :startGlyphCode

        def initialize(startCharCode:, endCharCode:, startGlyphCode:)
          @startCharCode = startCharCode
          @endCharCode = endCharCode
          @startGlyphCode = startGlyphCode
        end

        def length
          @endCharCode - @startCharCode + 1
        end
      end

      class CMAP::NotImplemented < StandardError
      end
    end
  end
end
