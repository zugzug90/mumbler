local flow = require "ludobits.m.flow"

require "lib.utf8lib"

local M = {}

local cyrrilic_transliteration_table = {}
cyrrilic_transliteration_table['а'] = 'a'
cyrrilic_transliteration_table['б'] = 'b'
cyrrilic_transliteration_table['в'] = 'v'
cyrrilic_transliteration_table['г'] = 'g'
cyrrilic_transliteration_table['д'] = 'd'
cyrrilic_transliteration_table['е'] = 'e'
cyrrilic_transliteration_table['ё'] = 'o'
cyrrilic_transliteration_table['ж'] = 'z'
cyrrilic_transliteration_table['з'] = 'z'
cyrrilic_transliteration_table['и'] = 'i'
cyrrilic_transliteration_table['к'] = 'k'
cyrrilic_transliteration_table['л'] = 'l'
cyrrilic_transliteration_table['м'] = 'm'
cyrrilic_transliteration_table['н'] = 'n'
cyrrilic_transliteration_table['о'] = 'o'
cyrrilic_transliteration_table['п'] = 'p'
cyrrilic_transliteration_table['р'] = 'r'
cyrrilic_transliteration_table['с'] = 's'
cyrrilic_transliteration_table['т'] = 't'
cyrrilic_transliteration_table['у'] = 'u'
cyrrilic_transliteration_table['ф'] = 'f'
cyrrilic_transliteration_table['х'] = 'h'
cyrrilic_transliteration_table['ц'] = 't'
cyrrilic_transliteration_table['ч'] = 'c'
cyrrilic_transliteration_table['ш'] = 's'
cyrrilic_transliteration_table['щ'] = 's'
cyrrilic_transliteration_table['ъ'] = 'y'
cyrrilic_transliteration_table['ы'] = 'y'
cyrrilic_transliteration_table['ь'] = 'y'
cyrrilic_transliteration_table['э'] = 'a'
cyrrilic_transliteration_table['ю'] = 'u'
cyrrilic_transliteration_table['я'] = 'i'

--{абвгдеёжзийклмнопрстуфхшщцыъъэюя}
-- Abvgdieiozhziyklmnoprstufkhshschtsy''eiuia


local function transliterate_to_latin_char(char) 
	for k, v in pairs(cyrrilic_transliteration_table) do
		if char == k then 
			return v
		end
	end
	return nil
end

function M.play_voice_line(text, sound_url, props)
	local sound_duration_seconds = props.sound_duration_seconds
	local overlapping_koeff = props.overlapping_koeff
	local on_char_start_pronouncing = props.on_char_start_pronouncing
	local on_char_end_pronouncing = props.on_char_end_pronouncing
	local on_non_alphanumeric_char_met = props.on_non_alphanumeric_char_met
	local on_complete = props.on_complete
	local overlapping_koeff_effective = overlapping_koeff or 0
	local vary_char_pronounce = props.vary_char_pronounce
	if vary_char_pronounce == nil then 
		vary_char_pronounce = true
	end
	local pronounce_terminal_chars_as_pauses = props.pronounce_terminal_chars_as_pauses
	if pronounce_terminal_chars_as_pauses == nil then 
		pronounce_terminal_chars_as_pauses = false
	end
	local pause_pronounce_duration_seconds = props.pause_pronounce_duration_seconds or 0.65
	
	flow(function()
		--print("Flow has started")

		local c 
		for i = 1, string.utf8len(text) do
			c = string.utf8sub(text, i, i)
			--print('           - Char code:', string.byte(string.lower(c)), 'corresponds to:', cyrrilic_transliteration_table[string.byte(string.lower(c))])
			local latin_char = cyrrilic_transliteration_table[(string.lower(c))] or string.lower(c)
			print('Latin char: ', latin_char, '(' .. string.byte(string.lower(c)) .. ')')
			local char_code = string.byte(latin_char)
			local v = (char_code % 26) / 26.0

			--if not (t[i] == ' ' or t[i] == '.' or t[i] == ',' or t[i] == '!' or t[i] == ';' or t[i] == '(' or t[i] == ')' or t[i] == '?' or t[i] == '-') then 
			if (latin_char:match("%w")) then 
				if on_char_start_pronouncing then 
					on_char_start_pronouncing(c)
				end
				
				local speed = 1
				local gain = 0.5
				if vary_char_pronounce == true then 
					speed = 1 + 0.25 * v
					gain = 0.5 + v
				end
				
				sound.play(sound_url, {gain = gain, pan = 0.0, speed = speed})
				flow.delay(sound_duration_seconds * (1 - overlapping_koeff_effective) / speed)
				if on_char_end_pronouncing then 
					on_char_end_pronouncing(c)
				end
			else 
				if on_non_alphanumeric_char_met then 
					on_non_alphanumeric_char_met(c)
					if (latin_char == '.' or latin_char == '!' or latin_char == '?' or latin_char == ';') and pronounce_terminal_chars_as_pauses == true then
						flow.delay(pause_pronounce_duration_seconds)
					end
				end
			end
		end
		if on_complete then
			on_complete(text)
		end
	end)
end

return M