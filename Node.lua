--[[
This file is part of xmldom. It is subject to the licence terms in the COPYRIGHT file found in the top-level directory of this distribution and at https://raw.githubusercontent.com/pallene-modules/xmldom/master/COPYRIGHT. No part of xmldom, including this file, may be copied, modified, propagated, or distributed except according to the terms contained in the COPYRIGHT file.
Copyright © 2015 The developers of xmldom. See the COPYRIGHT file in the top-level directory of this distribution and at https://raw.githubusercontent.com/pallene-modules/xmldom/master/COPYRIGHT.
]]--


local halimede = require('halimede')
local xmldom = require('xmldom')
local assert = halimede.assert
local areInstancesEqual = halimede.table.equality.areInstancesEqual
local Node = halimede.moduleclass('Node')


function module:initialize()
end

function module:isOtherThanElement()
	return not self:isElement()
end

function module:isComment()
	return self.class.isComment
end

function module:isElement()
	return self.class.isElement
end

function module:isProcessingInstruction()
	return self.class.isProcessingInstruction
end

function module:isText()
	return self.class.isText
end

function module:isElementWithSimpleName(simpleName)
	if self:isOtherThanElement() then
		return false
	end
	
	return self:hasSimpleName(simpleName)
end

function module:isElementWithNamespaceUriPrefixedName(namespaceUri, simpleName)
	if self:isOtherThanElement() then
		return false
	end
	
	return self:hasNamespaceUriPrefixedName(namespaceUri, simpleName)
end
