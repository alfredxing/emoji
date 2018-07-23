module Emoji
	module TTF
		module Tables
			# `name` table
			# Contains strings (copyright, font family name, etc)
			class NAME
				attr_reader :names

				def initialize(raw)
					@bytes = raw

					header()
					records()
				end

				# Table header
				#
				# Offset    Type        Name
				# 0         UInt16      format (unused)
				# 2         UInt16      count
				# 4         UInt16      stringOffset
				def header
					_, @count, @stringOffset = @bytes[0, 6].unpack('nnn')
				end

				# Name records
				# (Offset 6 from start of table)
				#
				# Offset    Type        Name
				# 0         UInt16      platformID (unused)
				# 2         UInt16      platformSpecificID (unused)
				# 4         UInt16      languageID (unused)
				# 6         UInt16      nameID
				# 8         UInt16      length
				# 10        UInt16      offset
				def records
					@names = {}

					@count.times do |n|
						start = 6 + n * 12
						_, _, _, nameID, length, offset = @bytes[start, 12].unpack('nnnnnn')

						@names[nameID] = @bytes[@stringOffset + offset, length]
					end
				end
			end
		end
	end
end
