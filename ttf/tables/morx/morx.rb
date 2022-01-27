module Emoji
  module TTF
    module Tables
      # `morx` table
      #
      # Extended glyph metamorphosis table; in the context of Apple Emoji, we are
      # interested in the ligatures defined (e.g. for skin tones and variants)
      class MORX
        def initialize(raw)
          @bytes = raw

          header()
          chains()
        end

        # Table header
        #
        # Offset    Type        Name
        # 0         UInt16      version (unused)
        # 2         UInt16      reserved (unused)
        # 4         UInt32      nChains
        def header
          @version, @reserved, @nChains = @bytes[0, 8].unpack('nnN')
        end

        # Chains
        def chains
          if @chains then
            return @chains
          end

          start = 8
          @chains = (0...@nChains).map do |n|
            chain = Chain.new(@bytes[start...@bytes.length])
            start += chain.chainLength

            chain
          end
        end
      end

      # Represents a `morx` table chain
      class MORX::Chain
        attr_reader :defaultFlags, :chainLength, :nFeatureEntries, :nSubtables

        def initialize(bytes)
          @bytes = bytes

          header()
          features()
          subtables()
        end

        # Chain header
        #
        # Offset    Type        Name
        # 0         UInt32      defaultFlags
        # 4         UInt32      chainLength
        # 8         UInt32      nFeatureEntries
        # 12        UInt32      nSubtables
        def header
          @defaultFlags, @chainLength, @nFeatureEntries, @nSubtables = @bytes[0, 16].unpack('NNNN')
        end

        # Feature entries
        # (Offset by 16 bytes from start of table)
        #
        # Offset    Type        Name
        # 0         UInt16      featureType
        # 2         UInt16      featureSetting
        # 4         UInt32      enableFlags
        # 6         UInt32      disableFlags
        def features
          if @features then
            return @features
          end

          @features = (0...@nFeatureEntries).map do |i|
            start = 16 + i * 12
            featureType, featureSetting, enableFlags, disableFlags = @bytes[start, 8].unpack('nnnn')

            Feature.new(
              featureType: featureType,
              featureSetting: featureSetting,
              enableFlags: enableFlags,
              disableFlags: disableFlags,
            )
          end
        end

        # Metamorphosis subtables
        # (Offset by 16 bytes from start of table, plus feature entries)
        #
        # Offset    Type        Name
        # 0         UInt32      length
        # 4         UInt32      coverage
        # 8         UInt32      subFeatureFlags
        def subtables
          if @subtables then
            return @subtables
          end

          start = 16 + @nFeatureEntries * 12
          @subtables = (0...@nSubtables).map do |i|
            length, coverage, subFeatureFlags = @bytes[start, 12].unpack('NNN')
            type = coverage & 0x000000FF

            case type
            when 2
              subtable = Subtable::Ligature.new(
                length: length,
                coverage: coverage,
                subFeatureFlags: subFeatureFlags,
                type: type,
                bytes: @bytes[start + 12, length - 12],
              )
            else
              subtable = nil
            end

            start += length
            subtable
          end
        end
      end

      # Represents a `morx` chain feature entry
      class MORX::Chain::Feature
        attr_reader :featureType, :featureSetting, :enableFlags, :disableFlags

        def initialize(featureType:, featureSetting:, enableFlags:, disableFlags:)
          @featureType = featureType
          @featureSetting = featureSetting
          @enableFlags = enableFlags
          @disableFlags = disableFlags
        end
      end

      # Represents a `morx` chain subtable
      class MORX::Chain::Subtable
        attr_reader :length, :coverage, :subFeatureFlags, :type

        def initialize(length:, coverage:, subFeatureFlags:, type:, bytes:)
          @length = length
          @coverage = coverage
          @subFeatureFlags = subFeatureFlags
          @type = type
          @bytes = bytes
        end
      end
    end
  end
end
