--[[
This file is part of xmldom. It is subject to the licence terms in the COPYRIGHT file found in the top-level directory of this distribution and at https://raw.githubusercontent.com/pallene-modules/xmldom/master/COPYRIGHT. No part of xmldom, including this file, may be copied, modified, propagated, or distributed except according to the terms contained in the COPYRIGHT file.
Copyright © 2015 The developers of xmldom. See the COPYRIGHT file in the top-level directory of this distribution and at https://raw.githubusercontent.com/pallene-modules/xmldom/master/COPYRIGHT.
]]--


local halimede = require('halimede')
local xmldom = require('xmldom')
local slaxml = xmldom.slaxml
local assert = halimede.assert
local isInstanceOf = halimede.type.isInstanceOf
local exception = halimede.exception
local areInstancesEqual = halimede.table.equality.areInstancesEqual
local Attribute = xmldom.Attribute
local CommentNode = xmldom.CommentNode
local ElementNode = xmldom.ElementNode
local Document = halimede.moduleclass('Document')
local Nodes = xmldom.Nodes
local ProcessingInstructionNode = xmldom.ProcessingInstructionNode
local FileHandleStream = halimede.io.FileHandleStream
local DefaultShellLanguage = halimede.io.shellScript.ShellLanguage.default()
local InternedStringMap = halimede.string.InternedStringMap


module.static.DefaultParsingOptions = {
	-- slaxml
	stripWhitespace = false,
	
	-- xmldom
	onlyAllowOneRootElement = true,
	xmlDeclarationMustBePresent = true,
	xmlDeclarationMustBeValid = true,
}

module.static.newDocumentFromOptions = function(options)
	local onlyAllowOneRootElement = options.onlyAllowOneRootElement
	if onlyAllowOneRootElement == nil then
		onlyAllowOneRootElement = true
	end
	
	local strictXmlDeclarationProcessing = options.strictXmlDeclarationProcessing
	if strictXmlDeclarationProcessing == nil then
		strictXmlDeclarationProcessing = true
	end
	
	return Document:new(onlyAllowOneRootElement, strictXmlDeclarationProcessing)
end

module.static.parseFromStringPathOrStandardIn = function(stringPathOrHyphen, description, options, keepElementMatcher)
	assert.parameterTypeIsString('stringPathOrHyphen', stringPathOrHyphen)
	assert.parameterTypeIsString('description', description)
	assert.parameterTypeIsTable('options', options)
	
	local xmlString = FileHandleStream.readEitherStandardInOrFileContentsIntoString(stringPathOrHyphen, description)
	return Document.parseFromString(xmlString, options, keepElementMatcher)
end

module.static.KeepElementRegardless = function(parents, namespaceUri, simpleName)
	return true
end

module.static.keepElementNodeIfMatchInSimpleNamesPath = function(...)
	local elementSimpleNamesPath = {...}
	local pathLength = #elementSimpleNamesPath
	
	return function(parents, namespaceUri, simpleName)
		local numberOfParents = #parents
		
		if simpleName ~= elementSimpleNamesPath[numberOfParents + 1] then
			return false
		end
		
		local index = 1
		while index <= numberOfParents do
			local parent = parents[index]
			if not parent:hasSimpleName(elementSimpleNamesPath[index]) then
				return false
			end
			index = index + 1
		end
		
		return true
	end
end

module.static.keepElementNodeIfMatchOneOfSeveralSimpleNamePaths = function(...)
	
	local matchers = {}
	for _, elementSimpleNamesPath in ipairs({...}) do
		matchers[#matchers + 1] = Document.keepElementNodeIfMatchInSimpleNamesPath(unpack(elementSimpleNamesPath))
	end
	
	return Document.keepElementNodeIfMatchOneOfSeveral(unpack(matchers))
end

module.static.keepElementNodeIfMatchOneOfSeveral = function(...)
	local matchers = {...}
	
	return function(parents, namespaceUri, simpleName)
		for _, matcher in ipairs(matchers) do
			if matcher(parents, namespaceUri, simpleName) then
				return true
			end
		end
		
		return false
	end
end

function module:initialize(onlyAllowOneRootElement, strictXmlDeclarationProcessing)
	assert.parameterTypeIsBoolean('onlyAllowOneRootElement', onlyAllowOneRootElement)
	assert.parameterTypeIsBoolean('strictXmlDeclarationProcessing', strictXmlDeclarationProcessing)
	
	self.onlyAllowOneRootElement = onlyAllowOneRootElement
	self.strictXmlDeclarationProcessing = strictXmlDeclarationProcessing
	self.xmlDeclaration = nil
	self.nodes = Nodes:new({})
	self.root = nil
end

function module:__tostring()
	return ('document:%s'):format(self.root)
end

local simpleEqualityFieldNames = {}
local shallowArrayFieldNames = {'children'}
local potentiallyNilFieldNames = {}
function module:__eq(right)
	return areInstancesEqual(self, right, simpleEqualityFieldNames, shallowArrayFieldNames, potentiallyNilFieldNames)
end

local IgnoreElementAndChildren = false
local push = table.insert
local pop = table.remove
module.static.parseFromString = function(xmlString, options, keepElementMatcher)
	assert.parameterTypeIsString('xmlString', xmlString)
	assert.parameterTypeIsTable('options', options)
	
	local internedStringMap = InternedStringMap:new()
	local document = Document.newDocumentFromOptions(options)
	local current = document
	
	-- local garbageCollectionCounter = 0
		
	local stack = {}
	
	local slaxmlParser = slaxml:parser{
		startElement = function(uninternedSimpleName, potentiallyNilUninternedNamespaceUri, potentiallyNilNamespacePrefix)
			local namespaceUri = internedStringMap:internStringAndRetrieveInternedString(potentiallyNilUninternedNamespaceUri, xmldom.NoNamespaceUri)
			local simpleName = internedStringMap:internStringAndRetrieveInternedString(uninternedSimpleName, nil)
						
			if current ~= IgnoreElementAndChildren or keepElementMatcher(stack, namespaceUri, simpleName) then
				local element = ElementNode:new(namespaceUri, simpleName, Nodes:new({}))
				current:addElement(element)
				current = element
			else
				current = IgnoreElementAndChildren
			end
			push(stack, current)
		end,
		
		attribute = function(uninternedSimpleName, value, potentiallyNilUninternedNamespaceUri, potentiallyNilNamespacePrefix)
			if current == IgnoreElementAndChildren then
				return
			end
			
			local namespaceUri = internedStringMap:internStringAndRetrieveInternedString(potentiallyNilUninternedNamespaceUri, xmldom.NoNamespaceUri)
			local simpleName = internedStringMap:internStringAndRetrieveInternedString(uninternedSimpleName, nil)
			local attribute = Attribute:new(namespaceUri, simpleName, value)
			
			current:addAttribute(attribute)
		end,
		
		closeElement = function(uninternedSimpleName, potentiallyNilUninternedNamespaceUri, potentiallyNilNamespacePrefix)
			pop(stack)
			current = stack[#stack]
			
			-- garbageCollectionCounter = garbageCollectionCounter + 1
			-- if garbageCollectionCounter % 100000 == 0 then
			-- 	local sizeInMegaBytes = halimede.math.toInteger(collectgarbage('count') / 1024)
			-- 	-- 1.5Mb
			-- 	if sizeInMegaBytes > 1536 then
			-- 		collectgarbage()
			-- 	end
			-- end
			
		end,
		
		text = function(text)
			if current == IgnoreElementAndChildren then
				return
			end
						
			current:addOrCoalesceText(text)
		end,
		
		comment = function(comment)
			if current == IgnoreElementAndChildren then
				return
			end
			
			current:addComment(CommentNode:new(comment))
		end,
		
		pi = function(uninternedName, unparsedAttributes)
			if current == IgnoreElementAndChildren then
				return
			end
			
			local name = internedStringMap:internStringAndRetrieveInternedString(uninternedName, nil)
			
			local processingInstruction = ProcessingInstructionNode:new(name, unparsedAttributes)
			if current:is(ElementNode) then
				if document.strictXmlDeclarationProcessing and processingInstruction:isXmlDeclaration() then
					exception.throw('XML declarations are not allowed within elements')
				end
			end
			
			current:addProcessingInstruction(processingInstruction)
		end
	}
	
	local slaxmlOptions = {}
	local stripWhitespace = options.stripWhitespace
	if stripWhitespace == nil then
		stripWhitespace = false
	end
	
	slaxmlParser:parse(xmlString, {
		stripWhitespace = stripWhitespace
	})
	collectgarbage()
	return document
end

function module:hasRoot()
	return self.root ~= nil
end

function module:useRoot(callback)
	if self:hasRoot() then
		return callback(self.root)
	end
end

function module:useRootIfMatchingNamespaceUriPrefixedName(namespaceUri, simpleName, callback)
	return self:findExactlyOneChildElementMatchingNamespaceUriPrefixedName(namespaceUri, simpleName, callback)
end

function module:guardHasXmlDeclaration()
	if self.strictXmlDeclarationProcessing then
		if self.xmlDeclaration == nil then
			exception.throw('Must have a XML declaration before adding nodes')
		end
	end
end

function module:addComment(comment)
	self.nodes:addComment(comment)
end

function module:addProcessingInstruction(processingInstruction)
	assert.parameterTypeIsInstanceOfOrNil('processingInstruction', processingInstruction, ProcessingInstructionNode)
	
	-- Whilst the XML declaration is not a processing instruction, folks often think it is and so treating as one allows more leniency for slightly invalid data
	if processingInstruction:isXmlDeclaration() and self.strictXmlDeclarationProcessing then
		if self.xmlDeclaration ~= nil then
			exception.throw('Only one XML declaration is permitted')
		end
		
		if not self.nodes:isEmpty() then
			exception.throw('XML declaration must occur before any nodes')
		end
		
		self.xmlDeclaration = processingInstruction:xmlDeclarationPseudoAttributes()
		
		return
	end
	
	self.nodes:addProcessingInstruction(processingInstruction)
end

function module:addOrCoalesceText(text)
	return self.nodes:addOrCoalesceText(text)
end

function module:addElement(element)
	self.nodes:addElement(element)
	
	if self.root == nil then
		self.root = element
	else
		if self.onlyAllowOneRootElement then
			exception.throw("Multiple root elements are not permitted in this context")
		end
		self.root = nil
	end
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
