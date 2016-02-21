
package.path = package.path .. ";../src/?.lua"

local luaunit = require('luaunit')
local httpmock = require('httpmock')
local mockluup = require('luup')
local util = require('util')
local daikinAttribute = require('DaikinAttribute')
local daikin = require('Daikin')
local controller = require('L_DaikinWifiController')

TestHttp = {}
	function TestHttp:testRequest()
		local response = http.request("hhttp://192.168.178.148/aircon/get_control_info")
		--print(response)
		luaunit.assertNotNil(response)
	end

-- end of table TestHttp

TestUtil ={}

	function TestUtil:testNoIpSet()
		local ip = getIp(2)
		luaunit.assertEquals(ip,"")
	end

	function TestUtil:testGetIp()
		luup.attr_set("ip","192.168.178.148","1")
		local ip = getIp(1)
		luaunit.assertNotNil(ip)
		luaunit.assertEquals(ip,"192.168.178.148")
	end

	function TestUtil:testNoDeviceCode()
		local code = getDeviceCode(2)
		luaunit.assertEquals(code,"")
	end

	function TestUtil:testGetDeviceCode()
		luup.attr_set("altid","1","1")
		local code = getDeviceCode(1)
		luaunit.assertNotNil(code)
		luaunit.assertEquals(code,"1")
	end

	function TestUtil:testSetLuupVariable()
		setLuupVariable("TEST_ID","Test Name",13,12)
		local returnValue = luup.variable_get("TEST_ID","Test Name",12)
		-- print(returnValue)
		luaunit.assertEquals(returnValue,13)
	end
    

	function TestUtil:testGetLuupVariable()
		setLuupVariable("TEST_ID2","Test Name2",12,10)
		
		local returnValue = getLuupVariable("TEST_ID2","Test Name2",10,T_NUMBER)
		-- print(returnValue)

		luaunit.assertEquals(returnValue,12)
	end

	function TestUtil:testParseBody()
		local valuePairs = parseBody("ret=OK,pow=0,mode=3,adv=,stemp=17.0,shum=0,dt1=25.0,dt2=M,dt3=18.0,dt4=25.0,dt5=25.0,dt7=25.0,dh1=AUTO,dh2=50,dh3=0,dh4=0,dh5=0,dh7=AUTO,dhh=50,b_mode=3,b_stemp=17.0,b_shum=0,alert=255")
		luaunit.assertNotNil(valuePairs)
		luaunit.assertEquals(valuePairs["ret"],"OK")
	end

	function TestUtil:testHexToASCII()
		local hexString = "%4c%6f%75%6e%67%65"
		local asciiString = hexToASCII(hexString)

		luaunit.assertEquals(asciiString,"Lounge")
	end

-- end of table TestUtil

TestDaikinAttribute = {}

	function TestDaikinAttribute:testNewAttribute()
		local attr = DaikinAttribute:new("Test Attribute","Test Service name","urn:upnp-org:serviceId:HVAC_UserOperatingMode1",1,1)
		luaunit.assertEquals(attr.description,"Test Attribute")
		luaunit.assertEquals(attr.name,"Test Service name")
		luaunit.assertEquals(attr.SERVICE_SID,"urn:upnp-org:serviceId:HVAC_UserOperatingMode1")
		luaunit.assertEquals(attr.value,1)
		luaunit.assertEquals(attr.deviceId,1)
		
		attr.value = 2
		luaunit.assertEquals(attr.value,2)

		attr:setValue(3)
		luaunit.assertEquals(attr.value,3)
	end
-- end of table TestDaikinAttribute

TestDaikin = {}


	function TestDaikin:testInitVariableIfNotSet()
		local attrib = initVariableIfNotSet("Test Desc",  "Test name", "TEST_ID", 120, 150)

		luaunit.assertEquals(attrib.name,"Test name")	
		luaunit.assertNotNil(attrib)
	end

	function TestDaikin:testInitVariables()
		local attribs = initVariables(111)
		
		luaunit.assertEquals(attribs["test"].name,"variableName")	
		luaunit.assertNotNil(attribs)
	end

	function TestDaikin:testNewDaikinDevice()
		local device = Daikin.new(1)

		luaunit.assertNotNil(device)
		luaunit.assertEquals(device.deviceId,1)

		luaunit.assertNotNil(device.attributes)
		luaunit.assertEquals(device.attributes["test"].name,"variableName")	
	end

	function TestDaikin:testSetAttribute()
		local device = Daikin.new(1)

		device:setAttribute("stemp",18.0)

		luaunit.assertNotNil(device.attributes)
		luaunit.assertEquals(device.attributes["stemp"].value,18.0)	
	end
	
	function TestDaikin:testSetAttributes()
		local device = Daikin.new(1)
		device:setAttributes(parseBody("r_ret=OKs,pow=0,mode=3,adv=,stemp=19.0,shum=0,dt1=25.0,dt2=M,dt3=18.0,dt4=25.0,dt5=25.0,dt7=25.0,dh1=AUTO,dh2=50,dh3=0,dh4=0,dh5=0,dh7=AUTO,dhh=50,b_mode=3,b_stemp=18.0,b_shum=0,alert=255")
)
		luaunit.assertNotNil(device.attributes)
		luaunit.assertEquals(device.attributes["stemp"].value,19.0)	
	end
	
	function TestDaikin:testGetCommandString()
		local device = Daikin.new(1)
		device:setAttributes(parseBody("r_ret=OKs,pow=0,mode=3,adv=,stemp=19.0,shum=0,dt1=25.0,dt2=M,dt3=18.0,dt4=25.0,dt5=25.0,dt7=25.0,dh1=AUTO,dh2=50,dh3=0,dh4=0,dh5=0,dh7=AUTO,dhh=50,b_mode=3,b_stemp=18.0,b_shum=0,alert=255")
)
		local commandString = device:getCommandString()
		luaunit.assertEquals(commandString,"pow=0&mode=3&stemp=19.0&shum=0&f_rate=0&f_dir=0")
	end

-- end of table TestDaikin

TestDaikinWifiController = {}

	function TestDaikinWifiController:testSendCommandFailOnAltId()
		daikin_device_id = 1
		luaunit.assertFalse(sendCommand("Test_URL", "", 0))
	end
	
	function TestDaikinWifiController:testSendCommand()
		daikin_device_id = 200
		daikin_device = Daikin.new(daikin_device_id)

		luup.attr_set("altid",12,daikin_device_id)
		luup.attr_set("ip","192.168.178.148",daikin_device_id)
		
		sendCommand("/common/basic_info", "", 0)
		luaunit.assertEquals(daikin_device.attributes["name"].value,"Lounge")
	end

	function TestDaikinWifiController:testDeviceUpdate()
		daikin_device_id = 201
		daikin_device = Daikin.new(daikin_device_id)

		luup.attr_set("altid",12,daikin_device_id)
		luup.attr_set("ip","192.168.178.148",daikin_device_id)

		deviceUpdate()

		luaunit.assertNotNil(luup.variable_get("urn:micasaverde-com:serviceId:HaDevice1", "LastUpdate", daikin_device_id))
		luaunit.assertEquals(daikin_device.attributes["htemp"].value,26.5)
	end

	function TestDaikinWifiController:testIntiPlugin()
		daikin_device_id = 201

		initPlugin()
		luaunit.assertEquals(luup.variable_get("urn:asahani-org:serviceId:DaikinWifiController1", "PluginVersion", daikin_device_id),"0.01")
		luaunit.assertEquals(luup.variable_get("urn:micasaverde-com:serviceId:HaDevice1", "Configured", daikin_device_id),0)
	end

	function TestDaikinWifiController:testDaikinStartup()
		luup.attr_set("altid",12,202)
		luup.attr_set("ip","192.168.178.148",202)

		DaikinStartup("202")

		luaunit.assertEquals(tonumber(luup.variable_get("urn:micasaverde-com:serviceId:HaDevice1", "Configured", 202)),1)
	end

	function TestDaikinWifiController:testSetpoint()
		luup.attr_set("altid",12,202)
		luup.attr_set("ip","192.168.178.148",202)

		DaikinStartup("203")
		setpoint("203","25")

		luaunit.assertEquals(daikin_device.attributes["stemp"].value,"25.0")
	end

	function TestDaikinWifiController:testSetModeTarget()
		luup.attr_set("altid",12,202)
		luup.attr_set("ip","192.168.178.148",202)

		DaikinStartup("203")
		setModeTarget("203","CoolOn")

		luaunit.assertEquals(daikin_device.attributes["mode"].value,"3")
	end

	function TestDaikinWifiController:testSetFanSpeed()
		luup.attr_set("altid",12,202)
		luup.attr_set("ip","192.168.178.148",202)

		DaikinStartup("203")
		setFanSpeed("203",64)

		luaunit.assertEquals(daikin_device.attributes["f_rate"].value,6)
	end

		function TestDaikinWifiController:testSetFanMode()
		luup.attr_set("altid",12,202)
		luup.attr_set("ip","192.168.178.148",202)

		DaikinStartup("203")
		setFanMode("203","Auto")

		luaunit.assertEquals(daikin_device.attributes["f_rate"].value,"A")
	end

-- end of Table TestDaikinWifiController	


os.exit(luaunit.LuaUnit.run())