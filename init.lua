-- Switch a GPIO on and off using two MQTT messages
-- 20150630 Luc Small lucsmall.com
-- Lua code for ESP8266 flashed with Nodemcu
--
-- Responds to:
--  /fairylights/on
--  /fairylights/off
--
-- Test with:
--  mosquitto_pub -t "/fairylights/on" -m ""
--  mosquitto_pub -t "/fairylights/off" -m ""


-- SSID and password of wifi router to connect to
wifi_ssid = "SSID"
wifi_password = "password"

-- MQTT Broker (e.g. mosquitto) to connect to
mqtt_broker_ip = "192.168.1.233"
mqtt_broker_port = 1883

mqtt_on_topic = "/fairylights/on"
mqtt_off_topic = "/fairylights/off"


-- Output pin for LED control
-- Control nodemcu pin 1 = D1 = GPIO5
-- Change to suit your application
-- Refer to: https://raw.githubusercontent.com/nodemcu/nodemcu-devkit-v1.0/master/Documents/NODEMCU_DEVKIT_V1.0_PINMAP.png
-- for complete pin mapping
-- for instance 4 = D4 = GPIO2
output_led = 1

-- Set up output pin as output, and set to off initially
gpio.mode(output_led, gpio.OUTPUT)
gpio.write(output_led, gpio.LOW)

-- Initialise mqtt client
m = mqtt.Client(wifi.sta.getmac(), 120, "user", "password")

m:on("offline", function(con) 
     print ("reconnecting...") 
     print(node.heap())
     tmr.alarm(1, 10000, 0, function()
          m:connect(mqtt_broker_ip, mqtt_broker_port, 0)
     end)
end)

-- on publish message receive event
m:on("message", function(conn, topic, data) 
  print(topic .. ":" ) 

  if topic == mqtt_on_topic then
    print("turning output on")
    gpio.write(output_led, gpio.HIGH)
  elseif topic == mqtt_off_topic then
    print("turning output off")
    gpio.write(output_led, gpio.LOW)
  end
  -- print message data, if any received
  if data ~= nil then
    print(data)
  end
end)

print("set station mode")
wifi.setmode(wifi.STATION)
print("set ssid and psk")

wifi.sta.config(wifi_ssid, wifi_password)
print("waiting for wifi to come up...")

-- wait until wifi is up before attempting connection to broker
tmr.alarm(0, 1000, 1, function()
 if wifi.sta.status() == 5 then
     tmr.stop(0)
     ip = wifi.sta.getip()
     print("my ip is ", ip)
     m:connect(mqtt_broker_ip, mqtt_broker_port, 0, function(conn)
          print("connected")
          m:subscribe({[mqtt_on_topic]=0,[mqtt_off_topic]=0}, function(conn) print("subscribed") end)
     end)
 end
end)
