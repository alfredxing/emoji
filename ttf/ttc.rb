module Emoji
	module TTF
		# Processes the TTC (TrueType Container) font container.
		# A TTC file is a simple header followed by the TTF fonts it contains.
		#
		# Offset    Type        Name
		# 0         TAG         ttcTag
		# 4         UInt16      majorVersion
		# 6         UInt16      minorVersion
		# 8         UInt32      numFonts
		# 12        UInt32[]    offsetTable[numFonts]
		class TTC
			attr_reader :fonts

			def initialize(bytes)
				@bytes = bytes

				validate()
				process()
			end

			def validate()
				if @bytes[0, 4] != 'ttcf' then
					raise 'Invalid TTC'
				end
			end

			def process()
				# TTC header
				majorVersion, minorVersion, numFonts = @bytes[4, 8].unpack('nnN')
				offsetTable = @bytes[12, (4 * numFonts)].unpack('N' * numFonts)

				@fonts = offsetTable.map do |offset|
					TTF.new(@bytes[offset, @bytes.length], offset)
				end
			end
		end
	end
end
