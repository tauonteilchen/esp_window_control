

data = {}
data.window = {}
data.indoor = {}
data.room = {}
data.button = {}

data.indoor.temperature  = 0
data.indoor.humidity = 0
data.indoor.gpio = 1                 
data.indoor.intervall = 5           
data.indoor.last = 0

data.window.open = 18              
data.window.close =  90	             
data.window.state = 0
data.window.last_event = 0
data.window.gpio = 2

data.button.gpio = 3

data.room.min_temperature = 18

function log_dht(dht_pin)
	status,temp,humi,temp_decimial,humi_decimial = dht.read(data.indoor.gpio)
	
	if( status == dht.OK ) then
		--value = { dht { time=""..tmr.time(), tepmerature  = ""..temp, humidity = ""..humi} }
		value = { indoor= { temperature = ""..temp, humidity=""..humi, stamp = ""..tmr.time()} }
		data.indoor.temperature  = temp
       	json_text = cjson.encode(value)
       	print(json_text)
       	file.open("log.txt", "a+")
    		file.writeline(json_text)
    		file.close()
       end
       return temp, humi 
  end

function run_main_timer(data)
	tmr.alarm(1, 500, 0, function() main(data) end )
end

function main(data)
	now =  tmr.time()
	interval = 0
	
	-- logging
	if data.indoor.last +  data.indoor.intervall  * 60 < now then
		data.indoor.temperature, data.indoor.humidity = log_dht(data.indoor.gpio)
		data.indoor.last = now
	end
	
	if data.window.state == 1 then
		interval = data.window.open
		--if data.room.min_temperature < data.indoor.temperature then
		--	interval = data.window.open
		--else
		--	print("cold")
		--end
	else
		interval = data.window.close
	end
	secondes_to_wait = (interval * 60) 
	
	-- window event hanling
	if  data.window.last_event + secondes_to_wait < now then
		gpio.write(data.window.gpio, gpio.LOW)
		tmr.delay(500)
		gpio.write(data.window.gpio, gpio.HIGH)
		data.window.state = ((data.window.state + 1) % 2)
		data.window.last_event = now
		msg = "opend for the next " ..data.window.open.. " minutes"
		if data.window.state == 0 then
			msg = "closed for the next " ..data.window.close.. " minutes"
		end
		print("window is " ..msg)
		--print("window change state " ..tmr.time())
	end
	
	run_main_timer(data)
end

function button_event(level)
	
	if level == 1 then 
		gpio.trig(data.button.gpio, "down") 
		gpio.write(data.window.gpio, gpio.HIGH)
	else 
		gpio.trig(data.button.gpio, "up") 
		gpio.write(data.window.gpio, gpio.LOW)
	end
end
   
tmr.delay(2000)

print("Window Control Center V00.01")
gpio.mode(data.button.gpio,gpio.INT,gpio.PULLUP)
gpio.mode(data.indoor.gpio,gpio.OUTPUT,gpio.PULLUP)
gpio.mode(data.window.gpio, gpio.OUTPUT,gpio.PULLUP)
gpio.write(data.window.gpio, gpio.LOW)
tmr.delay(200)
gpio.write(data.window.gpio, gpio.HIGH)

gpio.trig(data.button.gpio, "down",button_event)
--file.remove("log.txt")
  
print("Ready to start ap staion")
status,temp,humi,temp_decimial,humi_decimial = dht.read(data.indoor.gpio)
data.indoor.temperature = temp
data.indoor.humidity = humi

if data.room.min_temperature < data.indoor.temperature then
	print("warm genug")
else
	print("kalt")
end
--main loop
print(data.indoor.temperature)
tmr.alarm(1, 250 , 0, function() main(data) end )
print("startup done")