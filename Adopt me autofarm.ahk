
#Requires AutoHotkey v2.0

; Configuration file path
configFile := "coordinates_config.ini"

; Default coordinates (will be overwritten by saved config if it exists)
coordinates := Map(
    "bed", {x: 654, y: 303},
    "toilet", {x: 610, y: 615},
    "piano", {x: 690, y: 850},
    "bath", {x: 1225, y: 400},
    "water", {x: 1300, y: 580},
    "food", {x: 1300, y: 740},
    "backpack", {x: 960, y: 1030},
    "stroller_icon", {x: 810, y: 750},
    "stroller", {x: 980, y: 710},
    "stroller_equip", {x: 1090, y: 800},
    "close_backpack", {x: 1190, y: 640},
    "pet_position", {x: 615, y: 620},
    "remove_stroller", {x: 1060, y: 980},
    "toy_icon", {x: 755, y: 850},
    "toy_equip", {x: 1090, y: 800},
    "toy_position", {x: 980, y: 710},
    "use_toy", {x: 1120, y: 1010},
    "clickpet", {x: 615, y: 620},     
    "taskselect", {x: 615, y: 620},
    "taskselect2", {x: 615, y: 620},
    "taskselect3", {x: 615, y: 620},
    "taskselect4", {x: 615, y: 620},
    "taskselect5", {x: 615, y: 620},
    "unlocktask", {x: 615, y: 620},
    "taskexit", {x: 615, y: 620},
    "clickno", {x: 615, y: 620}
)

; Configuration mode
ConfigureCoordinates() {
    global coordinates
    
    result := MsgBox("Configuration mode will start.nnPress F1 to set coordinates for each position.nPress Esc to cancel configuration.", "Configure Coordinates", 1)
    if (result = "Cancel")
        return false

    ; Define the configuration order
    configOrder := [
        {key: "bed", prompt: "bed position"},
        {key: "toilet", prompt: "toilet position"},
        {key: "piano", prompt: "piano position"},
        {key: "bath", prompt: "bath position"},
        {key: "water", prompt: "water position"},
        {key: "food", prompt: "food position"},
        {key: "backpack", prompt: "backpack position"},
        {key: "stroller_icon", prompt: "stroller icon position"},
        {key: "stroller", prompt: "stroller position"},
        {key: "stroller_equip", prompt: "stroller equip button position"},
        {key: "close_backpack", prompt: "close backpack position"},
        {key: "pet_position", prompt: "pick up pet position"},
        {key: "remove_stroller", prompt: "remove stroller position"},
        {key: "toy_icon", prompt: "toy icon position"},
        {key: "toy_position", prompt: "pick toy position"},
        {key: "toy_equip", prompt: "toy equip button position"},
        {key: "use_toy", prompt: "use toy position"},
        {key: "clickpet", prompt: "position to click the pet"},
        {key: "taskselect", prompt: "position to select task 1"},
        {key: "taskselect2", prompt: "position to select task 2"},
        {key: "taskselect3", prompt: "position to select task 3"},
        {key: "taskselect4", prompt: "position to select task 4"},
        {key: "taskselect5", prompt: "position to select task 5"},
        {key: "unlocktask", prompt: "position to unlock task"},
        {key: "taskexit", prompt: "position to exit the task"},
        {key: "clickno", prompt: "position to click No button"}
    ]
    
    for config in configOrder {
        result := MsgBox(
            "Move your mouse to the " config.prompt " and press F1 to save it.nn" 
            "Click OK then move your mouse.nn"
            "Current action: " config.prompt, 
            "Set Position", 1)
            
        if (result = "Cancel")
            return false
        
        while true {
            if GetKeyState("Escape", "P") {
                MsgBox("Configuration cancelled!", "Cancelled", 48)
                return false
            }
            
            if GetKeyState("F1", "P") {
                MouseGetPos(&xpos, &ypos)
                coordinates[config.key].x := xpos
                coordinates[config.key].y := ypos
                MsgBox("Saved " config.prompt ": " xpos ", " ypos, "Position Saved", 64)
                Sleep(500)
                break
            }
            
            Sleep(50)
        }
    }
}    

SaveConfig() {
    global coordinates, configFile
    
    try {
        ; Create a new file or overwrite existing
        fileContent := ""
        for key, value in coordinates {
            fileContent .= key "," value.x "," value.y "`n"
        }
        FileDelete(configFile)
        FileAppend(fileContent, configFile)
        return true
    }
    catch Error as e {
        MsgBox("Error saving configuration: " e.Message, "Error", 16)
        return false
    }
}

LoadConfig() {
    global coordinates, configFile
    
    try {
        if FileExist(configFile) {
            fileContent := FileRead(configFile)
            
            ; Split the content into lines
            lines := StrSplit(fileContent, "`n", "`r")
            
            ; Process each line
            for line in lines {
                if line = "" ; Skip empty lines
                    continue
                    
                ; Split the line into parts
                parts := StrSplit(line, ",")
                if parts.Length >= 3 {
                    key := parts[1]
                    x := Integer(parts[2])
                    y := Integer(parts[3])
                    
                    ; Update coordinates if key exists
                    if coordinates.Has(key)
                        coordinates[key] := {x: x, y: y}
                }
            }
            return true
        }
    }
    catch Error as e {
        MsgBox("Error loading configuration: " e.Message, "Error", 16)
    }
    return false
}

; Create the main menu GUI
mainGui := Gui("+AlwaysOnTop", "Automation Menu")
mainGui.Add("Button", "w200 h30", "Start Automation").OnEvent("Click", StartAutomation)
mainGui.Add("Button", "w200 h30 y+5", "Configure Coordinates").OnEvent("Click", ConfigurePositions)
mainGui.Add("Button", "w200 h30 y+5", "Reset to Defaults").OnEvent("Click", ResetDefaults)
mainGui.Add("Button", "w200 h30 y+5", "Exit").OnEvent("Click", (*) => ExitApp())
mainGui.Show()

StartAutomation(*) {
    result := MsgBox("Press OK to start the automation.nPress Esc at any time to stop.", "Start Automation", 1)
    if (result = "Cancel")
        return
    
    ; Try to find and activate the Roblox window
    if WinExist("Roblox") {
        WinActivate "Roblox"
    } else if WinExist("ahk_exe RobloxPlayerBeta.exe") {
        WinActivate "ahk_exe RobloxPlayerBeta.exe"
    } else {
        MsgBox("Roblox window not found! Please make sure Roblox is running.", "Error", 16)
        return
    }
    
    ; Give a small delay to ensure window is focused
    Sleep 1000
    
    running := true
    while running {
        ; Bed
        MouseMove coordinates["bed"].x, coordinates["bed"].y
        Sleep 100
        MouseMove coordinates["bed"].x + 2, coordinates["bed"].y
        Sleep 100
        Click "down"
        Sleep 1002
        Click "up"
        Sleep 15000

        ; Toilet
        MouseMove coordinates["toilet"].x, coordinates["toilet"].y
        Sleep 100
        MouseMove coordinates["toilet"].x + 2, coordinates["toilet"].y
        Sleep 100
        Click "down"
        Sleep 100
        Click "up"
        Sleep 15000

        ; Piano
        MouseMove coordinates["piano"].x, coordinates["piano"].y
        Sleep 100
        MouseMove coordinates["piano"].x + 2, coordinates["piano"].y
        Sleep 100
        Click "down"
        Sleep 100
        Click "up"
        Sleep 500
        Send "{2}"
        Sleep 20000

        ; Bath
        MouseMove coordinates["bath"].x, coordinates["bath"].y
        Sleep 100
        MouseMove coordinates["bath"].x + 2, coordinates["bath"].y
        Sleep 100
        Click "down"
        Sleep 100
        Click "up"
        Sleep 15000

        ; Water
        MouseMove coordinates["water"].x, coordinates["water"].y
        Sleep 100
        MouseMove coordinates["water"].x + 2, coordinates["water"].y
        Sleep 100
        Click "down"
        Sleep 100
        Click "up"
        Sleep 15000

        ; Food
        MouseMove coordinates["food"].x, coordinates["food"].y
        Sleep 100
        MouseMove coordinates["food"].x + 2, coordinates["food"].y
        Sleep 100
        Click "down"
        Sleep 100
        Click "up"
        Sleep 15000

        ; Backpack
        MouseMove coordinates["backpack"].x, coordinates["backpack"].y
        Sleep 100
        MouseMove coordinates["backpack"].x + 2, coordinates["backpack"].y
        Sleep 100
        Click "down"
        Sleep 100
        Click "up"
        Sleep 500

        ; Stroller icon
        MouseMove coordinates["stroller_icon"].x, coordinates["stroller_icon"].y
        Sleep 100
        MouseMove coordinates["stroller_icon"].x + 2, coordinates["stroller_icon"].y
        Sleep 100
        Click "down"
        Sleep 100
        Click "up"
        Sleep 500

        ; Stroller
        MouseMove coordinates["stroller"].x, coordinates["stroller"].y
        Sleep 100
        MouseMove coordinates["stroller"].x + 2, coordinates["stroller"].y
        Sleep 100
        Click "down"
        Sleep 100
        Click "up"
        Sleep 500

        ; Equip Stroller
        MouseMove coordinates["stroller_equip"].x, coordinates["stroller_equip"].y
        Sleep 100
        MouseMove coordinates["stroller_equip"].x + 2, coordinates["stroller_equip"].y
        Sleep 100
        Click "down"
        Sleep 100
        Click "up"
        Sleep 500

        ; Close backpack
        MouseMove coordinates["close_backpack"].x, coordinates["close_backpack"].y
        Sleep 100
        MouseMove coordinates["close_backpack"].x + 2, coordinates["close_backpack"].y
        Sleep 100
        Click "down"
        Sleep 100
        Click "up"
        Sleep 500

        ; Pick up pet
        MouseMove coordinates["pet_position"].x, coordinates["pet_position"].y
        Sleep 100
        MouseMove coordinates["pet_position"].x + 2, coordinates["pet_position"].y
        Sleep 100
        Click "down"
        Sleep 100
        Click "up"
        Sleep 500
        Click "down"
        Sleep 100
        Click "up"

        ; Put pet into stroller
        Send "{r}"

        ; Jump
        Sleep 500
        Send "{Space down}"
        Sleep 200
        Send "{Space up}"
        Sleep 100
        Send "{Space down}"
        Sleep 20000
        Send "{Space up}"

        ; Sit down
        Sleep 1000
        Send "{e}"
        Sleep 100
        Send "{1}"
        Sleep 100

        ; Remove stroller
        MouseMove coordinates["remove_stroller"].x, coordinates["remove_stroller"].y
        Sleep 100
        MouseMove coordinates["remove_stroller"].x + 2, coordinates["remove_stroller"].y
        Sleep 100
        Click "down"
        Sleep 100
        Click "up"
        Sleep 500

        ; Pick up pet again
        MouseMove coordinates["pet_position"].x, coordinates["pet_position"].y
        Sleep 100
        MouseMove coordinates["pet_position"].x + 2, coordinates["pet_position"].y
        Sleep 100
        Click "down"
        Sleep 100
        Click "up"
        Sleep 500
        Click "down"
        Sleep 100
        Click "up"
        Sleep 500

        ; Jump again
        Send "{Space down}"
        Sleep 200
        Send "{Space up}"
        Sleep 100
        Send "{Space down}"
        Sleep 20000
        Send "{Space up}"

        ; Sit down again
        Sleep 1000
        Send "{e}"
        Sleep 100
        Send "{1}"
        Sleep 100

        ; Put down pet
        Send "{r}"
        Sleep 500

        ; Click No
        MouseMove coordinates["clickno"].x, coordinates["clickno"].y
        Sleep 100
        MouseMove coordinates["clickno"].x + 2, coordinates["clickno"].y
        Sleep 100
        Click "down"
        Sleep 100
        Click "up"

        ; Backpack again
        MouseMove coordinates["backpack"].x, coordinates["backpack"].y
        Sleep 100
        MouseMove coordinates["backpack"].x + 2, coordinates["backpack"].y
        Sleep 100
        Click "down"
        Sleep 100
        Click "up"
        Sleep 500

        ; Toy icon
        MouseMove coordinates["toy_icon"].x, coordinates["toy_icon"].y
        Sleep 100
        MouseMove coordinates["toy_icon"].x + 2, coordinates["toy_icon"].y
        Sleep 100
        Click "down"
        Sleep 100
        Click "up"
        Sleep 500

        ; Pick toy
        MouseMove coordinates["toy_position"].x, coordinates["toy_position"].y
        Sleep 100
        MouseMove coordinates["toy_position"].x + 2, coordinates["toy_position"].y
        Sleep 100
        Click "down"
        Sleep 100
        Click "up"
        Sleep 500

        ; Equip toy
        MouseMove coordinates["toy_equip"].x, coordinates["toy_equip"].y
        Sleep 100
        MouseMove coordinates["toy_equip"].x + 2, coordinates["toy_equip"].y
        Sleep 100
        Click "down"
        Sleep 100
        Click "up"

                ; Close backpack
                MouseMove coordinates["close_backpack"].x, coordinates["close_backpack"].y
                Sleep 100
                MouseMove coordinates["close_backpack"].x + 2, coordinates["close_backpack"].y
                Sleep 100
                Click "down"
                Sleep 100
                Click "up"
                Sleep 500
        
                ; Use toy (3 times)
                MouseMove coordinates["use_toy"].x, coordinates["use_toy"].y
                Sleep 100
                MouseMove coordinates["use_toy"].x + 2, coordinates["use_toy"].y
                Sleep 100
                Click "down"
                Sleep 100
                Click "up"
                Sleep 5000
                Click "down"
                Sleep 100
                Click "up"
                Sleep 5000
                Click "down"
                Sleep 100
                Click "up"
                Sleep 5000
        
                ; Turn off toy
                MouseMove coordinates["remove_stroller"].x, coordinates["remove_stroller"].y
                Sleep 100
                MouseMove coordinates["remove_stroller"].x + 2, coordinates["remove_stroller"].y
                Sleep 100
                Click "down"
                Sleep 100
                Click "up"
                Sleep 500
        
                ; Click No
                MouseMove coordinates["clickno"].x, coordinates["clickno"].y
                Sleep 100
                MouseMove coordinates["clickno"].x + 2, coordinates["clickno"].y
                Sleep 100
                Click "down"
                Sleep 100
                Click "up"
        
                ; Pick up pet one last time
                MouseMove coordinates["pet_position"].x, coordinates["pet_position"].y
                Sleep 100
                MouseMove coordinates["pet_position"].x + 2, coordinates["pet_position"].y
                Sleep 100
                Click "down"
                Sleep 100
                Click "up"
                Sleep 500
                Click "down"
                Sleep 100
                Click "up"
                Sleep 500
        
                ; Put down pet
                Sleep 500
                Send "{r}"
                Sleep 500
        
                ; Start of 5-task sequence
                ;Click Pet
                MouseMove coordinates["clickpet"].x, coordinates["clickpet"].y
                Sleep 100
                MouseMove coordinates["clickpet"].x + 2, coordinates["clickpet"].y
                Sleep 100
                Click "down"
                Sleep 100
                Click "up"
                Sleep 500
        
                ;task select
                MouseMove coordinates["taskselect"].x, coordinates["taskselect"].y
                Sleep 100
                MouseMove coordinates["taskselect"].x + 2, coordinates["taskselect"].y
                Sleep 100
                Click "down"
                Sleep 100
                Click "up"
                Sleep 500
        
                ;unlocktask
                MouseMove coordinates["unlocktask"].x, coordinates["unlocktask"].y
                Sleep 100
                MouseMove coordinates["unlocktask"].x + 2, coordinates["unlocktask"].y
                Sleep 100
                Click "down"
                Sleep 100
                Click "up"
         
                ; Exit Petselection
                Send "{e}"
                Sleep 500
        
                ;Click Pet
                MouseMove coordinates["clickpet"].x, coordinates["clickpet"].y
                Sleep 100
                MouseMove coordinates["clickpet"].x + 2, coordinates["clickpet"].y
                Sleep 100
                Click "down"
                Sleep 100
                Click "up"
                Sleep 500
        
                ;task select2
                MouseMove coordinates["taskselect2"].x, coordinates["taskselect2"].y
                Sleep 100
                MouseMove coordinates["taskselect2"].x + 2, coordinates["taskselect2"].y
                Sleep 100
                Click "down"
                Sleep 100
                Click "up"
                Sleep 500
        
                ;unlocktask
                MouseMove coordinates["unlocktask"].x, coordinates["unlocktask"].y
                Sleep 100
                MouseMove coordinates["unlocktask"].x + 2, coordinates["unlocktask"].y
                Sleep 100
                Click "down"
                Sleep 100
                Click "up"
         
                ; Exit Petselection
                Send "{e}"
                Sleep 500
        
                ;Click Pet
                MouseMove coordinates["clickpet"].x, coordinates["clickpet"].y
                Sleep 100
                MouseMove coordinates["clickpet"].x + 2, coordinates["clickpet"].y
                Sleep 100
                Click "down"
                Sleep 100
                Click "up"
                Sleep 500
                 
                ;task select3
                MouseMove coordinates["taskselect3"].x, coordinates["taskselect3"].y
                Sleep 100
                MouseMove coordinates["taskselect3"].x + 2, coordinates["taskselect3"].y
                Sleep 100
                Click "down"
                Sleep 100
                Click "up"
                Sleep 500
        
                ;unlocktask
                MouseMove coordinates["unlocktask"].x, coordinates["unlocktask"].y
                Sleep 100
                MouseMove coordinates["unlocktask"].x + 2, coordinates["unlocktask"].y
                Sleep 100
                Click "down"
                Sleep 100
                Click "up"
         
                ; Exit Petselection
                Send "{e}"
                Sleep 500
        
                ;Click Pet
                MouseMove coordinates["clickpet"].x, coordinates["clickpet"].y
                Sleep 100
                MouseMove coordinates["clickpet"].x + 2, coordinates["clickpet"].y
                Sleep 100
                Click "down"
                Sleep 100
                Click "up"
                Sleep 500
                 
                ;task select4
                MouseMove coordinates["taskselect4"].x, coordinates["taskselect4"].y
                Sleep 100
                MouseMove coordinates["taskselect4"].x + 2, coordinates["taskselect4"].y
                Sleep 100
                Click "down"
                Sleep 100
                Click "up"
                Sleep 500
        
                ;unlocktask
                MouseMove coordinates["unlocktask"].x, coordinates["unlocktask"].y
                Sleep 100
                MouseMove coordinates["unlocktask"].x + 2, coordinates["unlocktask"].y
                Sleep 100
                Click "down"
                Sleep 100
                Click "up"
         
                ; Exit Petselection
                Send "{e}"
                Sleep 500
        
                ;Click Pet
                MouseMove coordinates["clickpet"].x, coordinates["clickpet"].y
                Sleep 100
                MouseMove coordinates["clickpet"].x + 2, coordinates["clickpet"].y
                Sleep 100
                Click "down"
                Sleep 100
                Click "up"
                Sleep 500
                 
                ;task select5
                MouseMove coordinates["taskselect5"].x, coordinates["taskselect5"].y
                Sleep 100
                MouseMove coordinates["taskselect5"].x + 2, coordinates["taskselect5"].y
                Sleep 100
                Click "down"
                Sleep 100
                Click "up"
                Sleep 500
        
                ;unlocktask
                MouseMove coordinates["unlocktask"].x, coordinates["unlocktask"].y
                Sleep 100
                MouseMove coordinates["unlocktask"].x + 2, coordinates["unlocktask"].y
                Sleep 100
                Click "down"
                Sleep 100
                Click "up"
         
                ; Exit Petselection
                Send "{e}"
                Sleep 500
        
                ; Small jump to finish
                Send "{Space down}"
                Sleep 200
                Send "{Space up}"
                Sleep 1000
        
                if GetKeyState("Escape", "P") {
                    running := false
                    MsgBox("Script stopped!", "Stopped", 48)
                    break
                }
            }
        }
        
        ConfigurePositions(*) {
            ConfigureCoordinates()
        }
        
        ResetDefaults(*) {
            result := MsgBox("Are you sure you want to reset all coordinates to defaults?", "Reset Coordinates", 4)
            if (result = "Yes") {
                try {
                    FileDelete(configFile)
                    LoadConfig()
                    MsgBox("Coordinates reset to defaults!", "Success", 64)
                }
                catch Error as e {
                    MsgBox("Error resetting coordinates: " e.Message, "Error", 16)
                }
            }
        }
        
        Esc::ExitApp