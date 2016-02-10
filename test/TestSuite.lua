luaunit = require('luaunit')
httpmock = require('httpmock')

TestHttp = {}
	function TestHttp:testRequest()
		response = http.request("hhttp://192.168.178.148/aircon/get_control_info")
		--print(response)
		luaunit.assertNotNil(response)
	end

-- end of table TestHttp

os.exit(luaunit.LuaUnit.run())