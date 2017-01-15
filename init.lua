--[[
This file is part of xmldom. It is subject to the licence terms in the COPYRIGHT file found in the top-level directory of this distribution and at https://raw.githubusercontent.com/pallene-modules/xmldom/master/COPYRIGHT. No part of xmldom, including this file, may be copied, modified, propagated, or distributed except according to the terms contained in the COPYRIGHT file.
Copyright © 2015 The developers of xmldom. See the COPYRIGHT file in the top-level directory of this distribution and at https://raw.githubusercontent.com/pallene-modules/xmldom/master/COPYRIGHT.
]]--


local halimede = require('halimede')
local assert = halimede.assert


local NoNamespaceUri = ''
module.NoNamespaceUri = NoNamespaceUri

function module.toNamespaceUriPrefixedName(namespaceUri, simpleName)
	assert.parameterTypeIsString('namespaceUri', namespaceUri)
	assert.parameterTypeIsString('simpleName', simpleName)
	
	if namespaceUri == NoNamespaceUri then
		return simpleName
	else
		return namespaceUri .. ':' .. simpleName
	end
end
