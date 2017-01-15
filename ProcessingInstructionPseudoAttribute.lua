--[[
This file is part of xmldom. It is subject to the licence terms in the COPYRIGHT file found in the top-level directory of this distribution and at https://raw.githubusercontent.com/pallene-modules/xmldom/master/COPYRIGHT. No part of xmldom, including this file, may be copied, modified, propagated, or distributed except according to the terms contained in the COPYRIGHT file.
Copyright © 2015 The developers of xmldom. See the COPYRIGHT file in the top-level directory of this distribution and at https://raw.githubusercontent.com/pallene-modules/xmldom/master/COPYRIGHT.
]]--


local halimede = require('halimede')
local xmldom = require('xmldom')
local assert = halimede.assert
local exception = halimede.exception
local areInstancesEqual = halimede.table.equality.areInstancesEqual
local ProcessingInstructionPseudoAttribute = halimede.moduleclass('ProcessingInstructionPseudoAttribute')


function module:initialize(name, value)
	assert.parameterTypeIsString('name', name)
	assert.parameterTypeIsString('value', value)

	self.name = name
	self.value = value
end

function module:__tostring()
	return ('%s="%s"'):format(self.name, self.value)
end

local simpleEqualityFieldNames = {'namespaceUriPrefixedName', 'value'}
local shallowArrayFieldNames = {}
local potentiallyNilFieldNames = {}
function module:__eq(right)
	return areInstancesEqual(self, right, simpleEqualityFieldNames, shallowArrayFieldNames, potentiallyNilFieldNames)
end

function module:hasSimpleName(simpleName)
	assert.parameterTypeIsString('simpleName', simpleName)
	
	return self.simpleName == simpleName
end

function module:addValueUniquelyToTableWithValueValidationAndConversion(table, validPsuedoAttributeNamesTableOrNilIfAllAreValid)
	assert.parameterTypeIsTable('table', table)
	
	local name = self.name
	
	if table[name] ~= nil then
		exception.throw("Non unique psuedo-attribute '%s'", name)
	end
	
	local value = self.value
	local convertedValue
	if validPsuedoAttributeNamesTableOrNilIfAllAreValid ~= nil then
		local validationAndConversionFunction = validPsuedoAttributeNamesTableOrNilIfAllAreValid[name]
		if validationAndConversionFunction == nil then
			exception.throw("The pseduo-attribute '%s' has an invalid name", name)
		end
		convertedValue = validationAndConversionFunction(value)
		if convertedValue == nil then
			exception.throw("The pseduo-attribute '%s' is invalid or has an unsupported value '%s'", name, value)
		end
	else
		convertedValue = value
	end
		
	table[name] = convertedValue
end
