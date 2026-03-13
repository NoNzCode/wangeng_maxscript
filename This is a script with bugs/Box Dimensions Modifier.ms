/*
Box Dimensions Modifier Utility
Author: NoNzCode
Created: 2025-01-13 02:18:40 UTC
*/

rollout BoxDimensionsModifier "Box Dimensions Modifier" width:320
(
    -- UI Controls
    group "Dimension Settings"
    (
        spinner spn_length "Length: " type:#float range:[0,100000,100] width:270
        spinner spn_width "Width:  " type:#float range:[0,100000,100] width:270
        spinner spn_height "Height: " type:#float range:[0,100000,100] width:270
    )
    
    group "Modification Options"
    (
        checkbox chk_selectedOnly "Modify Selected Objects Only" checked:true
        checkbox chk_uniform "Uniform Scaling" checked:false
        dropdownlist ddl_presets "Presets:" items:#("Custom", "Cube", "Double All", "Half All") width:270
    )
    
    group "Apply Changes"
    (
        button btn_modifyAll "Apply All Dimensions" width:270 height:30
        button btn_modifyLength "Apply Length" width:130 align:#left across:2
        button btn_modifyWidth "Apply Width" width:130 align:#right
        button btn_modifyHeight "Apply Height" width:130 align:#left across:2
        button btn_reset "Reset All" width:130 align:#right
    )
    
    group "Statistics"
    (
        label lbl_stats "Modified Boxes: 0" align:#left
        label lbl_user "User: NoNzCode" align:#left
        label lbl_timestamp "Last Update: 2025-01-13 02:18:40" align:#left
    )

    -- Functions
    fn updateTimestamp = 
    (
        local time = getLocalTime()
        local timeStr = formattedPrint time format:"Last Update: YYYY-MM-DD HH:mm:ss"
        lbl_timestamp.text = timeStr
    )
    
    fn modifyBoxDimensions obj length:undefined width:undefined height:undefined = 
    (
        if (classOf obj == Box) then
        (
            try
            (
                if length != undefined do obj.length = length
                if width != undefined do obj.width = width
                if height != undefined do obj.height = height
                
                -- Visual feedback
                obj.wirecolor = color 0 255 0
                true
            )
            catch
            (
                format "Error modifying box: %\n" obj.name
                false
            )
        )
        else false
    )
    
    fn processBoxes length:undefined width:undefined height:undefined = 
    (
        local modifiedCount = 0
        local objectsToProcess = #()
        
        -- Determine which objects to process
        if chk_selectedOnly.checked then
            objectsToProcess = getCurrentSelection()
        else
            objectsToProcess = objects
        
        -- Start undo
        undo "Modify Box Dimensions" on
        (
            -- Process each object
            for obj in objectsToProcess do
            (
                if chk_uniform.checked and (length != undefined or width != undefined or height != undefined) then
                (
                    -- Use the first non-undefined value for uniform scaling
                    local uniformValue = length
                    if uniformValue == undefined do uniformValue = width
                    if uniformValue == undefined do uniformValue = height
                    
                    if (modifyBoxDimensions obj length:uniformValue width:uniformValue height:uniformValue) then
                        modifiedCount += 1
                )
                else
                (
                    if (modifyBoxDimensions obj length:length width:width height:height) then
                        modifiedCount += 1
                )
            )
        )
        
        -- Update statistics and timestamp
        lbl_stats.text = "Modified Boxes: " + modifiedCount as string
        updateTimestamp()
        
        -- Refresh viewport
        redrawViews()
    )
    
    fn applyPreset preset = 
    (
        case preset of
        (
            "Cube": 
            (
                spn_length.value = 100
                spn_width.value = 100
                spn_height.value = 100
            )
            "Double All":
            (
                local objectsToProcess = if chk_selectedOnly.checked then getCurrentSelection() else objects
                for obj in objectsToProcess where classOf obj == Box do
                (
                    modifyBoxDimensions obj \
                        length:(obj.length * 2) \
                        width:(obj.width * 2) \
                        height:(obj.height * 2)
                )
            )
            "Half All":
            (
                local objectsToProcess = if chk_selectedOnly.checked then getCurrentSelection() else objects
                for obj in objectsToProcess where classOf obj == Box do
                (
                    modifyBoxDimensions obj \
                        length:(obj.length * 0.5) \
                        width:(obj.width * 0.5) \
                        height:(obj.height * 0.5)
                )
            )
        )
        updateTimestamp()
        redrawViews()
    )
    
    -- Event Handlers
    on BoxDimensionsModifier open do
    (
        lbl_user.text = "User: " + sysInfo.username
        updateTimestamp()
    )
    
    on btn_modifyAll pressed do
    (
        processBoxes length:spn_length.value width:spn_width.value height:spn_height.value
    )
    
    on btn_modifyLength pressed do
    (
        processBoxes length:spn_length.value
    )
    
    on btn_modifyWidth pressed do
    (
        processBoxes width:spn_width.value
    )
    
    on btn_modifyHeight pressed do
    (
        processBoxes height:spn_height.value
    )
    
    on btn_reset pressed do
    (
        spn_length.value = 100
        spn_width.value = 100
        spn_height.value = 100
        processBoxes length:100 width:100 height:100
    )
    
    on ddl_presets selected val do
    (
        if val > 1 do -- Skip "Custom"
            applyPreset ddl_presets.items[val]
    )
    
    on chk_uniform changed state do
    (
        spn_width.enabled = not state
        spn_height.enabled = not state
        if state do
        (
            spn_width.value = spn_length.value
            spn_height.value = spn_length.value
        )
    )
    
    on spn_length changed val do
    (
        if chk_uniform.checked do
        (
            spn_width.value = val
            spn_height.value = val
        )
    )
)

-- Create the utility
if (BoxDimensionsModifier != undefined) do
(
    try(destroyDialog BoxDimensionsModifier)catch()
)
createDialog BoxDimensionsModifier