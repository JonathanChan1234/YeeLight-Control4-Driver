# YeeLight Smart LED Bulb (Xiaomi) Control4 Driver

> Control4 Driver to toggle, change RGB color, color temperature of Yeelight

> Compatible to OS 2.10 or above

### Sample Control Command

```bash
Get the current status of the light
{"id":1,"method":"get_prop","params":["power", "name", "rgb", "bright", "ct", "color_mode"]}
{"id":1,"method":"get_prop","params":["power", "name", "rgb", "bright", "ct"]}


Set the rgb value of the light
{"id":1,"method":"set_rgb","params":[16579587, "smooth", 500]}

Set the brightness of the light:
{"id":1,"method":"set_bright","params":[50, "smooth", 500]}

Toggle
{"id":1,"method":"toggle","params":[]}

Set name
{"id":1,"method":"set_name","params":["my_bulb"]}

Set cron Job
{"id":1,"method":"cron_add","params":[0, 1]}

Set scene
{"id":1,"method":"set_scene","params":["color", 16579587, 90]}
{"id":1,"method":"set_scene","params":["color",10027008, 85]}

Set brightness
{"id":1,"method":"adjust_bright","params":[-10, 500]}
```

### Proxy Binding Id

5001: Brightness

5002: Color Temperature

5003: Red

5004: Green

5005: Blue

### Control Binding Id

301: On Button Link

302: Off Button Link

303: Toggle Button Link

## Project Structure

1. action.lua

-   implement the function ExecuteCommand(strCommand, tParams)
-   handle the action tab

2. connection.lua

-   implement the function OnConnectionStatusChanged(idBinding, nPort, strStatus)
-   listen to the change of the TCP connection between the controller and yeelight

3. constants.lua

-   frequently used constants (proxy binding id, control binding id, property key value)

4. driver.lua

-   entry point of the whole driver

5. lighting_profile.lua

-   "get" and "set" the persist data table (provided by the control4 DriverWork SDK)
-   "YEELIGHT_PROFILE": contains the current color mode, RGB, color temperature and brightness
-   "YEELIGHT_HISTORY": contains the last known status of the yeelight
-   Both table contains the same data structure

6. network.lua

-   implement the function ReceivedFromNetwork (idBinding, nPort, receviedString)
-   handle the feedback data received from yeelight and update the driver property including the driver property in composer and proxy (mobile app)

7. properties.lua

-   implement the function OnPropertyChanged(strProperty)
-   listen to the change of driver properties (only apply for manual change)
-   will not be called for C4:UpdateProperty() function

8. proxy.lua

-   implement the function ReceivedFromProxy(bindingId, strCommand, tParams)
-   handle the ui interaction and update the light status correspondingly

9.  utils.lua

-   all the utility functions (mathematics, string, debug)
-   handle the conversion between level and actual value for rgb color and color temperature

10. yeelight_command.lua

-   implement the actual commands that will be sent to yeelight
