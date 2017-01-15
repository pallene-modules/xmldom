--[[
This file is part of xmldom. It is subject to the licence terms in the COPYRIGHT file found in the top-level directory of this distribution and at https://raw.githubusercontent.com/pallene-modules/xmldom/master/COPYRIGHT. No part of xmldom, including this file, may be copied, modified, propagated, or distributed except according to the terms contained in the COPYRIGHT file.
Copyright © 2015 The developers of xmldom. See the COPYRIGHT file in the top-level directory of this distribution and at https://raw.githubusercontent.com/pallene-modules/xmldom/master/COPYRIGHT.
]]--


local halimede = require('halimede')
local xmldom = require('xmldom')
local assert = halimede.assert
local areInstancesEqual = halimede.table.equality.areInstancesEqual
local Attribute = halimede.moduleclass('Attribute')


function module:initialize(namespaceUri, simpleName, value)
	assert.parameterTypeIsString('namespaceUri', namespaceUri)
	assert.parameterTypeIsString('simpleName', simpleName)
	assert.parameterTypeIsString('value', value)

	self.namespaceUri = namespaceUri
	self.simpleName = simpleName
	self.value = value
end

function module:__tostring()
	return ('%s="%s"'):format(self.simpleName, self.value)
end

local simpleEqualityFieldNames = {'namespaceUri', 'simpleName', 'value'}
local shallowArrayFieldNames = {}
local potentiallyNilFieldNames = {}
function module:__eq(right)
	return areInstancesEqual(self, right, simpleEqualityFieldNames, shallowArrayFieldNames, potentiallyNilFieldNames)
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
