http = {}

function http.request(request)
	if request.match(request,"/aircon/get_control_info") ~= nil then
		return "ret=OK,pow=0,mode=3,adv=,stemp=18.0,shum=0,dt1=25.0,dt2=M,dt3=18.0,dt4=25.0,dt5=25.0,dt7=25.0,dh1=AUTO,dh2=50,dh3=0,dh4=0,dh5=0,dh7=AUTO,dhh=50,b_mode=3,b_stemp=18.0,b_shum=0,alert=255"
	elseif request.match(request,"/aircon/get_model_info") ~= nil then
		return "ret=OK,htemp=26.5,hhum=-,otemp=-,err=0,cmpfreq=0"
	elseif request.match(request,"/aircon/get_sensor_info") ~= nil then
		return "ret=OK,htemp=26.5,hhum=-,otemp=-,err=0,cmpfreq=0"
	elseif request.match(request,"/aircon/get_target") ~= nil then
		return "ret=OK,target=0"
	elseif request.match(request,"/aircon/get_program") ~= nil then
		return "ret=OK,p=0,pmode=3,ccnt=0,wcnt=0"
	else	
		return request
	end	
end