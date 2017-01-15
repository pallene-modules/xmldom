--[[
This file is part of xmldom. It is subject to the licence terms in the COPYRIGHT file found in the top-level directory of this distribution and at https://raw.githubusercontent.com/pallene-modules/xmldom/master/COPYRIGHT. No part of xmldom, including this file, may be copied, modified, propagated, or distributed except according to the terms contained in the COPYRIGHT file.
Copyright © 2015 The developers of xmldom. See the COPYRIGHT file in the top-level directory of this distribution and at https://raw.githubusercontent.com/pallene-modules/xmldom/master/COPYRIGHT.
]]--


local halimede = require('halimede')
local xmldom = require('xmldom')
local slaxml = xmldom.slaxml
local Node = xmldom.Node
local assert = halimede.assert
local areInstancesEqual = halimede.table.equality.areInstancesEqual
local ProcessingInstructionPseudoAttribute = xmldom.ProcessingInstructionPseudoAttribute
local ProcessingInstructionNode = halimede.moduleclass('ProcessingInstructionNode', Node)


module.static.isComment = false
module.static.isElement = false
module.static.isProcessingInstruction = true
module.static.isText = false

function module:initialize(name, value)
	assert.parameterTypeIsString('name', name)
	assert.parameterTypeIsString('value', value)
	
	self.name = name
	self.value = value
end

function module:__tostring()
	return ('<?%s %s?>'):format(self.name, self.value)
end

local simpleEqualityFieldNames = {'name', 'value'}
local shallowArrayFieldNames = {}
local potentiallyNilFieldNames = {}
function module:__eq(right)
	return areInstancesEqual(self, right, simpleEqualityFieldNames, shallowArrayFieldNames, potentiallyNilFieldNames)
end

-- has pseudo attributes version="1.0" encoding="UTF-8" standalone="no"
function module:isXmlDeclaration()
	return 'xml' == self.name
end

local XmlDeclarationPsuedoAttributeValidators = {
	version = function(value)
		if value == '1.0' or value == '1.1' then
			return tonumber(value) * 10
		else
			return nil
		end
	end,
	encoding = function(value)
		-- Other values are valid but not supported
		if value == 'UTF-8' or value == 'US-ASCII' then
			return value
		else
			return nil
		end
	end,
	standalone = function(value)
		if value == 'yes' then
			return true
		elseif value == 'no' then
			return false
		else
			return nil
		end
	end,
}
local XmlDeclarationPsuedoAttributeDefaults = {
	version = 10,
	encoding = 'UTF-8',
	standalone = true,
}
function module:xmlDeclarationPseudoAttributes()
	if not self:isXmlDeclaration() then
		exception.throw('Not a XML declaration')
	end
	return self:parsePseudoAttributesAsATableWithDefaults(XmlDeclarationPsuedoAttributeValidators, XmlDeclarationPsuedoAttributeDefaults)
end

-- must appear in the prolog, before the document or root element
function module:isXmlStyleSheet()
	-- Expected pseudo attributes: https://www.w3.org/TR/xml-stylesheet/#the-xml-stylesheet-processing-instruction
	return 'xml-stylesheet' == self.name
end

local XmlStyleSheetPsuedoAttributeValidators = {
	href = function(value)
		return value
	end,
	type = function(value)
		return value
	end,
	title = function(value)
		return value
	end,
	-- Could be stricter: See https://www.w3.org/TR/css3-mediaqueries/
	media = function(value)
		return value
	end,
	charset = function(value)
		-- Other values are valid but not supported
		if value == 'UTF-8' or value == 'US-ASCII' then
			return value
		else
			return nil
		end
	end,
	alternate = function(value)
		if value == 'yes' then
			return true
		elseif value == 'no' then
			return false
		else
			return nil
		end
	end,
}
local XmlStyleSheetPseudoAttributeDefaults = {
	media = 'screen',
	charset = 'UTF-8',
	alternate = false,
}
function module:xmlStyleSheetPseudoAttributes()
	if not self:isXmlStyleSheet() then
		exception.throw('Not a XML style sheet')
	end
	return self:parsePseudoAttributesAsATableWithDefaults(XmlStyleSheetPsuedoAttributeValidators, XmlStyleSheetPseudoAttributeDefaults)
end

function module:parsePseudoAttributesAsATableWithDefaults(validPsuedoAttributeNamesTableOrNilIfAllAreValid, defaults)
	local table = {}
	
	self:parsePseudoAttributes(function(psuedoAttribute)
		psuedoAttribute:addValueUniquelyToTableWithValueValidationAndConversion(table, validPsuedoAttributeNamesTableOrNilIfAllAreValid)
	end)
	
	for defaultName, defaultValue in pairs(defaults) do
		if table[defaultName] == nil then
			table[defaultName] = defaultValue
		end
	end
	
	return table
end

function module:parsePseudoAttributesAsAnArray()
	local array = {}
	
	self:parsePseudoAttributes(function(psuedoAttribute)
		array[#array + 1] = psuedoAttribute
	end)
end

local fakeElementName = 'X'
function module:parsePseudoAttributes(callback)
	local slaxmlParser = slaxml:parser{
		startElement = function(uninternedSimpleName, potentiallyNilUninternedNamespaceUri, potentiallyNilNamespacePrefix)
			-- in theory, a psuedo-attribute could be named 'xmlns', so this test isn't perfect
			if uninternedSimpleName ~= fakeElementName or potentiallyNilUninternedNamespaceUri ~= nil or potentiallyNilNamespacePrefix ~= nil then
				exception.throw('Bad psuedo-attributes or a pseudo-attribute that is like a XML namespace xmlns is present')
			end
		end,
		
		attribute = function(uninternedSimpleName, value, potentiallyNilUninternedNamespaceUri, potentiallyNilNamespacePrefix)
			if potentiallyNilUninternedNamespaceUri ~= nil or potentiallyNilNamespacePrefix ~= nil then
				exception.throw("Bad psuedo-attribute '%s'", uninternedSimpleName)
			end
			
			callback(ProcessingInstructionPseudoAttribute:new(uninternedSimpleName, value))
		end,
		
		closeElement = function(uninternedSimpleName, potentiallyNilUninternedNamespaceUri, potentiallyNilNamespacePrefix)
			if uninternedSimpleName ~= fakeElementName or potentiallyNilUninternedNamespaceUri ~= nil or potentiallyNilNamespacePrefix ~= nil then
				exception.throw('Bad psuedo-attributes')
			end
		end,
		
		text = function(text)
			exception.throw('Should not be parsing text in psuedo-attributes of a XML processing instruction')
		end,
		
		comment = function(comment)
			exception.throw('Should not be parsing comments in psuedo-attributes of a XML processing instruction')
		end,
		
		pi = function(uninternedName, unparsedAttributes)
			exception.throw('Should not be parsing processing instructions in psuedo-attributes of a XML processing instruction')
		end
	}
	
	slaxmlParser:parse(self.value, {})
	collectgarbage()
end
