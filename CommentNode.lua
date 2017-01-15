--[[
This file is part of xmldom. It is subject to the licence terms in the COPYRIGHT file found in the top-level directory of this distribution and at https://raw.githubusercontent.com/pallene-modules/xmldom/master/COPYRIGHT. No part of xmldom, including this file, may be copied, modified, propagated, or distributed except according to the terms contained in the COPYRIGHT file.
Copyright © 2015 The developers of xmldom. See the COPYRIGHT file in the top-level directory of this distribution and at https://raw.githubusercontent.com/pallene-modules/xmldom/master/COPYRIGHT.
]]--


local halimede = require('halimede')
local xmldom = require('xmldom')
local Node = xmldom.Node
local assert = halimede.assert
local areInstancesEqual = halimede.table.equality.areInstancesEqual
local CommentNode = halimede.moduleclass('CommentNode', Node)


module.static.isComment = true
module.static.isElement = false
module.static.isProcessingInstruction = false
module.static.isText = false

function module:initialize(comment)
	assert.parameterTypeIsString('comment', comment)
	
	self.comment = comment
end

function module:__tostring()
	return ('<!--%s-->'):format(self.comment)
end

local simpleEqualityFieldNames = {'comment'}
local shallowArrayFieldNames = {}
local potentiallyNilFieldNames = {}
function module:__eq(right)
	return areInstancesEqual(self, right, simpleEqualityFieldNames, shallowArrayFieldNames, potentiallyNilFieldNames)
end
