--[[
This file is part of xmldom. It is subject to the licence terms in the COPYRIGHT file found in the top-level directory of this distribution and at https://raw.githubusercontent.com/pallene-modules/xmldom/master/COPYRIGHT. No part of xmldom, including this file, may be copied, modified, propagated, or distributed except according to the terms contained in the COPYRIGHT file.
Copyright © 2015 The developers of xmldom. See the COPYRIGHT file in the top-level directory of this distribution and at https://raw.githubusercontent.com/pallene-modules/xmldom/master/COPYRIGHT.
]]--


local halimede = require('halimede')
local xmldom = require('xmldom')
local Node = xmldom.Node
local assert = halimede.assert
local areInstancesEqual = halimede.table.equality.areInstancesEqual
local TextNode = halimede.moduleclass('TextNode', Node)


module.static.isComment = false
module.static.isElement = false
module.static.isProcessingInstruction = false
module.static.isText = true

-- xpath function equivalent is normalize-whitespace: https://developer.mozilla.org/en-US/docs/Web/XPath/Functions/normalize-space
module.static.normalizeSpaceAndTrim = function(text)
	
	-- XML White Space is only defined for ASCII code points; this lets us ignore the string encoding (assuming we're dealing with an ASCII, Latin-1 or UTF-8 document)
	-- 0x020 0x09 0x0D 0x0A
	local normalizedWhiteSpace = text:gsub('[\x20\x09\x0D\x0A]+', ' ')
	
	local length = #normalizedWhiteSpace
	
	-- Short circuits
	if length == 0 then
		return ''
	elseif length == 1 then
		if normalizedWhiteSpace == ' ' then
			return ''
		else
			return normalizedWhiteSpace
		end
	end
	
	local leadingIndex
	local subStringLength
	if normalizedWhiteSpace:byte(1) == ' ' then
		leadingIndex = 2
		subStringLength = length - 1
	else
		leadingIndex = 1
		subStringLength = length
	end

	if normalizedWhiteSpace:byte(length) == ' ' then
		subStringLength = subStringLength - 1
	end
	
	return normalizedWhiteSpace:sub(leadingIndex, subStringLength)
end

function module:initialize(text)
	assert.parameterTypeIsString('text', text)
	
	self.text = text
end

function module:normalizedText()
	return TextNode.normalizeSpaceAndTrim(self.text)
end

function module:coalesceText(text)
	self.text = self.text .. text
end

function module:__tostring()
	return ('%s'):format(self.text)
end

local simpleEqualityFieldNames = {'text'}
local shallowArrayFieldNames = {}
local potentiallyNilFieldNames = {}
function module:__eq(right)
	return areInstancesEqual(self, right, simpleEqualityFieldNames, shallowArrayFieldNames, potentiallyNilFieldNames)
end
