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
