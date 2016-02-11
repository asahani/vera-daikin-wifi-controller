package.path = package.path .. ";../src/?.lua"

luaunit = require('luaunit')
httpmock = require('httpmock')
mockluup = require('luup')
util = require('util')

TestHttp = {}
	function TestHttp:testRequest()
		response = http.request("hhttp://192.168.178.148/aircon/get_control_info")
		--print(response)
		luaunit.assertNotNil(response)
	end

-- end of table TestHttp

TestUtil ={}

	function TestUtil:testNoIpSet()
		ip = getIp(2)
		luaunit.assertEquals(ip,"")
	end

	function TestUtil:testGetIp()
		luup.attr_set("ip","192.168.178.148","1")
		ip = util.getIp(1)
		luaunit.assertNotNil(ip)
		luaunit.assertEquals(ip,"192.168.178.148")
	end

	function TestUtil:testNoDeviceCode()
		code = getDeviceCode(2)
		luaunit.assertEquals(code,"")
	end

	function TestUtil:testGetDeviceCode()
		luup.attr_set("altid","1","1")
		code = getDeviceCode(1)
		luaunit.assertNotNil(code)
		luaunit.assertEquals(code,"1")
	end

-- end of table TestUtil
os.exit(luaunit.LuaUnit.run())