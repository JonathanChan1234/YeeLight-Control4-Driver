# Yee Light Smart LED Bulb

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
{"id":1,"method":"adjust_bright","params":[50, 500]}
```

### Proxy

5001: Brightness

5002: Color Temperature

5003: Red

5004: Green

5005: Blue

#### Variables:

1. g_deviceAddress: ip address of the led light bulb
2. (redValue, redLevel), (blueValue, blueLevel), (greenValue, greenLevel): app (proxy) light level, actual light level

### Program Flow

1. App ==> Controller
   ReceivedFromProxy(idBinding, strCommand, tParams) -> CommandInterpreter -> send command to yeelight bulb through ip network
2. Light ==> Controller

    Create Telnet connection between light and controller

    C4:CreateNetworkConnection(6001, g_deviceAddress , "Telnet")

    Received Response from the light

    function ReceivedFromNetwork(idBinding, nPort, strData)

3. Controller ==> App
   C4:SendToProxy(idBinding, strCommand, tParams, strmessage)

### Command Intepreter (Received From Proxy)

#### Color Temperature Binding (5001)

1. Set RGB to all 0
2. If the command is "RAMP_TO_LEVEL",
