--[[
This file is part of xmldom. It is subject to the licence terms in the COPYRIGHT file found in the top-level directory of this distribution and at https://raw.githubusercontent.com/pallene-modules/xmldom/master/COPYRIGHT. No part of xmldom, including this file, may be copied, modified, propagated, or distributed except according to the terms contained in the COPYRIGHT file.
Copyright © 2015 The developers of xmldom. See the COPYRIGHT file in the top-level directory of this distribution and at https://raw.githubusercontent.com/pallene-modules/xmldom/master/COPYRIGHT.
]]--


local halimede = require('halimede')
local xmldom = require('xmldom')
local Node = xmldom.Node
local assert = halimede.assert
local areInstancesEqual = halimede.table.equality.areInstancesEqual
local Attribute = xmldom.Attribute
local CommentNode = xmldom.CommentNode
local ProcessingInstructionNode = xmldom.ProcessingInstructionNode
local TextNode = xmldom.TextNode
local ElementNode = halimede.moduleclass('ElementNode', Node)


module.static.isComment = false
module.static.isElement = true
module.static.isProcessingInstruction = false
module.static.isText = false

function module:initialize(namespaceUri, simpleName, nodes)
	assert.parameterTypeIsString('namespaceUri', namespaceUri)
	assert.parameterTypeIsString('simpleName', simpleName)

	self.namespaceUri = namespaceUri
	self.simpleName = simpleName
	self.attributes = {}
	self.nodes = nodes
end

function module:__tostring()
	
	local attributesString = ''
	for _, attribute in ipairs(self.attributes) do
		attributesString = attributesString .. ' ' .. attribute:__tostring()
	end
	
	if self.nodes:isEmpty() then
		return ('<%s%s/>'):format(self.simpleName, attributesString)
	else
		-- Can run out of memory quite easily
		local childrenString = '(children)'
		return ('<%s%s>%s</%s>'):format(self.simpleName, attributesString, childrenString, self.simpleName)
	end
	
end

local simpleEqualityFieldNames = {'namespaceUri', 'simpleName', 'nodes'}
local shallowArrayFieldNames = {'attributes'}
local potentiallyNilFieldNames = {}
function module:__eq(right)
	return areInstancesEqual(self, right, simpleEqualityFieldNames, shallowArrayFieldNames, potentiallyNilFieldNames)
end

-- Yes, permits multiples attributes of the same name or value or both; designed to make it easier to work with potentially invalid XML derived from HTML
function module:addAttribute(attribute)
	assert.parameterTypeIsInstanceOfOrNil('attribute', attribute, Attribute)
	
	self.attributes[#self.attributes + 1] = attribute
end

-- Yes, permits multiples attributes of the same name or value or both
function module:findAttributes(namespaceUri, simpleName)
	assert.parameterTypeIsString('namespaceUri', namespaceUri)
	assert.parameterTypeIsString('simpleName', simpleName)
	
	local attributesFound = {}
	
	for _, attribute in ipairs(self.attributes) do
		if attribute:hasNamespaceUriPrefixedName(namespaceUri, simpleName) then
			attributesFound[#attributesFound + 1] = attribute
		end
	end
	
	return attributesFound
end

function module:findExactlyOneAttributeAndReturnItsValueOrNil(namespaceUri, simpleName)
	local attributes = self:findAttributes(namespaceUri, simpleName)
	if #attributes ~= 1 then
		return nil
	end
	
	return attributes[1].value
end

function module:hasExactlyOneAttributeAndItsValueIs(namespaceUri, simpleName, value)
	local attributeValue = self:findExactlyOneAttributeAndReturnItsValueOrNil(namespaceUri, simpleName)
	if attributeValue == nil or attributeValue ~= value then
		return false
	else
		return true
	end
end

function module:hasSimpleName(simpleName)
	assert.parameterTypeIsString('simpleName', simpleName)
	
	return self.simpleName == simpleName
end

function module:hasNamespaceUriPrefixedName(namespaceUri, simpleName)
	assert.parameterTypeIsString('namespaceUri', namespaceUri)
	assert.parameterTypeIsString('simpleName', simpleName)

	-- check name first as very likely to be the shorter value
	return self.simpleName == simpleName and self.namespaceUri == namespaceUri
end

function module:addComment(comment)
	self.nodes:addComment(comment)
end

function module:addProcessingInstruction(processingInstruction)
	self.nodes:addProcessingInstruction(processingInstruction)
end

function module:addOrCoalesceText(text)
	return self.nodes:addOrCoalesceText(text)
end

function module:addElement(element)
	self.nodes:addElement(element)
end

function module:normalizedTextValueIfOnlyOneChildAndItIsATextNode()
	return self.nodes:normalizedTextValueIfOnlyOneChildAndItIsATextNode()
end

function module:iterateOverChildren(matcher, callback)
	return self.nodes:iterateOverChildren(matcher, callback)
end

function module:iterateOverElementsMatchingNamespaceUriPrefixedName(namespaceUri, simpleName, callback)
	return self.nodes:iterateOverElementsMatchingNamespaceUriPrefixedName(namespaceUri, simpleName, callback)
end

function module:findExactlyOneChildElementMatchingNamespaceUriPrefixedName(namespaceUri, simpleName, callback)
	return self.nodes:findExactlyOneChildElementMatchingNamespaceUriPrefixedName(namespaceUri, simpleName, callback)
end

function module:findFirstChildElementMatchingNamespaceUriPrefixedName(namespaceUri, simpleName, callback)
	return self.nodes:findFirstChildElementMatchingNamespaceUriPrefixedName(namespaceUri, simpleName, callback)
end
