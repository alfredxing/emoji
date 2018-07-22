require 'FileUtils'

f = File.open('Apple Color Emoji.ttc', 'rb')
contents = f.read

#
# TTF
# Processes the offset table at the beginning of the font
#
def ttf(bytes, fontOffset)
	sfntVersion, numTables, searchRange, entrySelector, rangeShift = bytes[0, 4 + 2 + 2 + 2 + 2].unpack('Nnnnn')

	tables = {}

	numTables.times do |n|
		start = 12 + n * 16
		tag = bytes[start, 4]
		checkSum, offset, length = bytes[start + 4, 12].unpack('NNN')
		# puts [tag, offset, length].inspect

		tables[tag] = bytes[offset - fontOffset, length]
	end

	tables['name'] = name(tables['name'])
	tables['maxp'] = maxp(tables['maxp'])
	tables['sbix'] = sbix(tables['sbix'], tables['maxp']['numGlyphs'])
end

#
# `maxp` table
# Memory requirements for the font; in particular we are interested in `numGlyphs`
#
def maxp(bytes)
	return {
		'version' => bytes[0, 4],
		'numGlyphs' => bytes[4, 2].unpack('n')[0]
	}
end

#
# `sbix` table
# Contains image bitmaps (emoji image data)
#
def sbix(bytes, numGlyphs)
	version, flags, numStrikes = bytes[0, 8].unpack('nnN')

	strikeOffset = [*0...numStrikes].map do |n|
		start = 8 + n * 4
		bytes[start, 4].unpack('N')[0]
	end

	strikes = strikeOffset.map do |offset|
		ppem, resolution = bytes[offset, 4].unpack('nn')
		glyphDataOffset = [*0...(numGlyphs + 1)].map do |n|
			bytes[offset + 4 + (n * 4), 4].unpack('N')[0]
		end

		glyphs = [*0...numGlyphs].map do |glyphID|
			start = glyphDataOffset[glyphID]
			length = glyphDataOffset[glyphID + 1] - start

			if length == 0 then
				nil
			else
				glyph = bytes[offset + start, length]
				originOffsetX, originOffsetY = glyph[0, 4].unpack('nn')
				graphicType = glyph[4, 4]
				data = glyph[8, length - 8]

				{
					'originOffsetX' => originOffsetX,
					'originOffsetY' => originOffsetY,
					'graphicType' => graphicType,
					'data' => data,
				}
			end
		end

		{
			'ppem' => ppem,
			'resolution' => resolution,
			'glyphDataOffset' => glyphDataOffset,
			'glyphs' => glyphs,
		}
	end

	strikes.each do |strike|
		ppem = strike['ppem']
		FileUtils.mkdir_p("extract/#{ppem}")

		strike['glyphs'].each_index do |id|
			if strike['glyphs'][id] != nil then
				File.open("extract/#{ppem}/#{id}.png", 'wb') do |f|
					f.write(strike['glyphs'][id]['data'])
				end
			end
		end
	end
end

#
# `name` table
# Contains strings (copyright, font family name, etc)
#
def name(bytes)
	format, count, stringOffset = bytes[0, 6].unpack('nnn')

	names = {}

	count.times do |n|
		start = 6 + n * 12
		_, _, _, nameID, length, offset = bytes[start, 12].unpack('nnnnnn')

		names[nameID] = bytes[stringOffset + offset, length]
	end

	return names
end

#
# TTC
# A TrueType collection is made up of multiple TTF-format fonts
#
def ttc(bytes)
	# Tag check
	if bytes[0, 4] != 'ttcf' then
		return
	end

	# TTC header
	majorVersion, minorVersion, numFonts = bytes[4, 8].unpack('nnN')
	offsetTable = bytes[12, (4 * numFonts)].unpack('N' * numFonts)

	offsetTable[0,1].each do |offset|
		ttf(bytes[offset, bytes.length], offset)
	end
end

ttc(contents)
