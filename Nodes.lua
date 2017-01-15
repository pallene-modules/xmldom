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
local ElementNode = xmldom.ElementNode
local Nodes = halimede.moduleclass('Nodes')


function module:initialize(children)
	self.children = children
end

function module:__tostring()
	return ('Nodes(%s)'):format(#self.children)
end

function module:isEmpty()
	return self:length() == 0
end

function module:length()
	return #self.children
end

function module:firstIsXmlDeclaration()
	local length = #self.children
	
	if length == 0 then
		return false
	end
	
	local first = self.children[1]
	
	return first:isProcessingInstruction() and first:isXmlDeclaration()
end

function module:addComment(comment)
	assert.parameterTypeIsInstanceOfOrNil('comment', comment, CommentNode)
	
	self.children[#self.children + 1] = comment
end

function module:addProcessingInstruction(processingInstruction)
	assert.parameterTypeIsInstanceOfOrNil('processingInstruction', processingInstruction, ProcessingInstructionNode)
	
	self.children[#self.children + 1] = processingInstruction
end

function module:addOrCoalesceText(text)
	assert.parameterTypeIsString('text', text)
	
	local currentLength = #self.children
	if currentLength == 0 then
		self.children[1] = TextNode:new(text)
		return false
	end
	
	local lastChild = self.children[currentLength]
	if lastChild:isText() then
		lastChild:coalesceText(text)
		return true
	end
		
	self.children[currentLength + 1] = TextNode:new(text)
	return false
end

function module:addElement(element)
	assert.parameterTypeIsInstanceOfOrNil('element', element, ElementNode)
	
	self.children[#self.children + 1] = element
end

function module:normalizedTextValueIfOnlyOneChildAndItIsATextNode()
	local text = nil
	
	if #self.children ~= 1 then
		return nil
	end
	
	local potentialText = self.children[1]
	if potentialText:isText() then
		return potentialText:normalizedText()
	else
		return nil
	end
end

function module:iterateOverChildren(matcher, callback)
	for _, childNode in ipairs(self.children) do
		if matcher(childNode) then
			local shouldBreak = callback(childNode)
			if shouldBreak == true then
				return true
			end
		end
	end
	return false
end

function module:iterateOverElementsMatchingNamespaceUriPrefixedName(namespaceUri, simpleName, callback)
	self:iterateOverChildren(
		function(childNode)
			return childNode:isElementWithNamespaceUriPrefixedName(namespaceUri, simpleName)
		end,
		callback
	)
end

function module:findExactlyOneChildElementMatchingNamespaceUriPrefixedName(namespaceUri, simpleName, callback)
	local oneAndOnlyOneChildElement
	local count = 0
	self:iterateOverElementsMatchingNamespaceUriPrefixedName(namespaceUri, simpleName, function(childElement)
		count = count + 1
		if count == 1 then
			oneAndOnlyOneChildElement = childElement
			return false
		else
			oneAndOnlyOneChildElement = nil
			return true
		end
	end)
	if count == 1 then
		return callback(oneAndOnlyOneChildElement)
	end
end

function module:findFirstChildElementMatchingNamespaceUriPrefixedName(namespaceUri, simpleName, callback)
	local oneAndOnlyOneChildElement
	local found = self:iterateOverElementsMatchingNamespaceUriPrefixedName(namespaceUri, simpleName, function(childElement)
		oneAndOnlyOneChildElement = childElement
		return true
	end)
	if found then
		return callback(oneAndOnlyOneChildElement)
	end
end
