-- xrayCSM By Mr Techtroid
-- Released Under MIT License
-- Version 1.0.0 (2023)
-- Copyright (C) 2023 Mr Techtroid
-- -----------------------------------------------------------------------------

local xrayCSM = {
    vno = "1.0.0",
    author = "Mr Techtroid",
    license = "MIT License",
    copyright = "Copyright (C) 2023 Mr Techtroid",
}

local waypointsstring = ""
local ores_table = {
    {"default:stone_with_diamond", "Diamond", 0x0933de},
    {"charoit:stone_with_charoit", "Charoit", 0xde09da},
    {"default:stone_with_emerald", "Emerald", 0x33de09},
    {"default:quartz_ore", "Quartz", 0x804000},
    {"default:stone_with_gold","Gold",0xfff000},
    {"default:stone_with_iron","Iron",0xffffff},
    {"default:chest","Chest",0x7c0a02},
    {"default:chest_left","Chest(l)",0x7c0a02},
}
local radius = 50

minetest.register_chatcommand("xrayCSM",{
    params = "",
    description = "Info About xrayCSM Mod",
    func = function()
        minetest.display_chat_message("---------------------------------------")
        minetest.display_chat_message("xrayCSM By Mr Techtroid")
        minetest.display_chat_message("Version:" .. xrayCSM["vno"] )
        minetest.display_chat_message("Released Under ".. xrayCSM["license"])
        minetest.display_chat_message("---------------------------------------")
    end,
})

local function find_nearest_ore_nodes(player, ores)
    local player_pos = player:get_pos()
    local waypoints = {}
    for _, ore in ipairs(ores) do
        local nodename, name, color = ore[1], ore[2], ore[3]
        local ore_nodes = minetest.find_nodes_in_area(
            vector.subtract(player_pos, radius),
            vector.add(player_pos, radius),
            {nodename})
        if #ore_nodes > 0 then
            for _, pos in ipairs(ore_nodes) do
                local waypoint = {
                    hud_elem_type = 'waypoint',
                    world_pos = pos,
                    name = name,
                    text = "m",
                    number = color,
                }
                local id = player:hud_add(waypoint)
                table.insert(waypoints, {id = id, pos = pos, name = name})
            end
        else
            print("No " .. name .. " ore found.")
        end
    end
    return waypoints
end


local function remove_waypoint(player, id)
    player:hud_remove(id)
end

local function on_dig(pos, node, digger)
    local waypoints = minetest.deserialize(waypointsstring) or {}
    if waypoints ~= "" then
        for i, wp in ipairs(waypoints) do
            if vector.equals(wp.pos, pos) then
                remove_waypoint(minetest.localplayer, wp.id)
                table.remove(waypoints, i)
                waypointsstring = minetest.serialize(waypoints)
                break
            end
        end
    end
end

minetest.register_on_dignode(on_dig)

local function clear_all()
    local waypoints = minetest.deserialize(waypointsstring)
    if waypointsstring == "" then
        return false
    end
    for _, wp in ipairs(waypoints) do
        minetest.localplayer:hud_remove(wp.id)
    end
    minetest.display_chat_message("All waypoints cleared.")
    waypointsstring = ""
end
local function add_ore(param)
    local nodename, orename, colorstr = param:match("(%S+)%s+(%S+)%s+(%S+)")
    if not nodename or not orename or not colorstr then
        return false, "Invalid parameters. Usage: /add_ore <nodename> <name> <color>"
    end
    local color = tonumber(colorstr, 16)
    if not color then
        return false, "Invalid color. Usage: /add_ore <nodename> <name> <color>"
    end
    for _, ore in ipairs(ores_table) do
        if ore[1] == nodename then
            minetest.display_chat_message("Ore with the same ID already exists")
            return false
        end
    end
    table.insert(ores_table, {nodename, orename, color})
    minetest.display_chat_message("Added " .. orename .. " to the `ores_table`.")
    return true
end
local function remove_ore(param)
    local orename = param:trim()
    for i, ore in ipairs(ores_table) do
        if ore[2] == orename then
            table.remove(ores_table, i)
            minetest.display_chat_message("Removed " .. orename .. " from the `ores_table`.")
            return true
        end
    end
    minetest.display_chat_message("Could not find " .. orename .. " in the `ores_table`.")
    clear_all()
    xrayHandler()
    return false
end
local function list_ores()
    local ore_names = {}
    if not ores_table then
        return false,"Ores Table is Empty"
    end
    for _, ore in ipairs(ores_table) do
        table.insert(ore_names, ore[2])
    end
    local ore_list = table.concat(ore_names, ", ")
    return "Ores: "..ore_list
end
local function set_radius(param)
    local new_radius = tonumber(param)
    if not new_radius or new_radius <= 0 or new_radius > 79 then
        minetest.display_chat_message("Invalid radius. Must be between 1 and 80.")
        return false
    end
    radius = new_radius
    minetest.display_chat_message("Radius set to " .. radius)
    return true
end
local function xrayHandler()
    local player = minetest.localplayer
    clear_all()
    local oresgh = find_nearest_ore_nodes(player, ores_table)
    if #oresgh > 0 then
        waypointsstring = minetest.serialize(oresgh) 
        minetest.display_chat_message("Found " .. #oresgh .. " nearby ore nodes")
    else 
        minetest.display_chat_message("No nearby ores found")
    end
end
minetest.register_chatcommand("xray", {
    params = "",
    description = "Find nearby ores and add waypoints to them",
    func = xrayHandler,
})

minetest.register_chatcommand("clear_all", {
    params = "",
    description = "Clears all HUD waypoints",
    func = clear_all
})

minetest.register_chatcommand("add_ore", {
    params = "<nodename> <name> <color>",
    description = "Add a new ore to the `ores_table`",
    func = function(param)
        return true, add_ore(param)
    end,
})

minetest.register_chatcommand("remove_ore", {
    params = "<name>",
    description = "Remove an ore from the `ores_table`",
    func = function(param)
        return true, remove_ore(param)
    end,
})
minetest.register_chatcommand("list_ores", {
    params = "",
    description = "List all ores in `ores_table`",
    func = function()
        return true, list_ores()
    end
})
minetest.register_chatcommand("set_radius", {
    params = "<radius>",
    description = "Set the radius to search for ores",
    func = function(param)
        return true, set_radius(param)
    end,
})
local UI_str = ""
local function showUI()
    local ore_names = {}
    if not ores_table then
        return false,"Ores Table is Empty"
    end
    for _, ore in ipairs(ores_table) do
        table.insert(ore_names, ore[2])
    end
    local ore_list = table.concat(ore_names, ", ")
    local xray_gui = [[
    formspec_version[6]
    size[11,9]
    box[0.4,1;5,4.5;#fffff]
    label[2.7,1.4;Add]
    field[0.8,2.1;4.2,0.5;ore_id;Ore ID:;]
    field[0.8,3.1;4.2,0.5;ore_name;Ore Name:;]
    field[0.8,4.1;4.2,0.5;ore_color;Color:;]
    button[1.5,4.8;2.6,0.6;add_ore;Add Ore]
    label[3.8,0.7;xrayCSM by MTT]
    box[5.7,1;5,4.7;]
    label[6.7,1.4;Mod Properties]
    field[6,3.3;2.5,0.5;xray_radius;Radius:;]].. radius .. [[]
    button[8.7,3;1.8,0.8;set_radius;Set]
    button[6,4;4.5,0.7;clear_all;Clear All Waypoints]
    button[6,2;4.5,0.7;xray;Find Ores]
    box[0.5,6;4.9,2.5;]
    label[2.3,6.3;Remove]
    field[0.7,7;4.4,0.5;r_ore_name;Ore Name:;]
    button[1.5,7.7;2.9,0.6;remove_ore;Remove Ore]
    box[5.7,6;4.9,2.5;]
    textarea[5.9,6.6;4.5,1.8;xrayCSM_orelist;Ore List;]].. ore_list ..[[]
    button_exit[10.2,0.1;0.7,0.6;xray_exit;X]
    ]]
    xray_gui = xray_gui .. UI_str
    if UI_str == "" then
        UI_str = " "
    else 
        UI_str = ""
    end
    minetest.show_formspec('xray:main_menu', xray_gui)
end

minetest.register_chatcommand('x', {
    description = 'Open the X-Ray menu',
    func = function(name)
        showUI()
        return true
    end,
})
minetest.register_on_formspec_input(function(formname, fields)
    if formname == "xray:main_menu" then
        if fields.add_ore then
            local ore_id = fields.ore_id
            local ore_name = fields.ore_name
            local ore_color = fields.ore_color
            local param = ore_id .. " " .. ore_name .. " " .. ore_color
            add_ore(param)
            showUI()
            return true
        elseif fields.remove_ore then
            remove_ore(fields.r_ore_name)
            showUI()
            return true
        elseif fields.set_radius then
            set_radius(fields.xray_radius)
            showUI()
            return true
        elseif fields.clear_all then
            clear_all()
            return true
        elseif fields.xray then
            xrayHandler()
            return true
        end
        
    end
end)

minetest.register_on_mods_loaded(function() minetest.send_chat_message("Player used xrayCSM") end)