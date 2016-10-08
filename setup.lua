assert(fs.exists("disk"),"Please attach a disk drive to install files to!")

local copyfiles = {
	"relgo.lua",
	"config.lua",
	"miner.lua",
	"json.lua",
	"swarm.lua"
}

local blacklist = {
	{name="minecraft:cobblestone"},
	{name="minecraft:stone"},
	{name="minecraft:sandstone"},
	{name="minecraft:grass"},
	{name="minecraft:tallgrass"},
	{name="minecraft:dirt"},
	{name="minecraft:gravel"},
	{name="minecraft:sand"},
	{name="minecraft:bedrock"},
	{name="minecraft:snow_layer"},
	{name="minecraft:ice"},
	{name="ProjRed|Exploration:projectred.exploration.stone",metadata=0},
	{name="chisel:limestone"},
	{name="chisel:chisel.limestone"},
	{name="chisel:marble"},
	{name="chisel:chisel.marble"},
	{name="chisel:diorite"},
	{name="chisel:granite"},
	{name="chisel:andesite"},
	{name="Railcraft:cube",metadata=7}
}

for i,v in ipairs(copyfiles) do
	assert(fs.exists(".sq/"..v),"Missing required file: "..v.. " - please redownload the setup.")
end

local deploy_code = [[
assert(turtle, "This disk is to deploy turtle swarm miners!")
print("Deploy this turtle as miner? [Y/N]")
local _,key = os.pullEvent("char")
if key == "y" then
	print("Copying files...")
	fs.copy("disk/relgo.lua","relgo.lua")
	fs.copy("disk/config.lua","config.lua")
	fs.copy("disk/miner.lua","miner.lua")
	fs.copy("disk/json.lua","json.lua")
	fs.copy("disk/swarm.lua","swarm.lua")
	fs.copy("disk/.swarmconfig",".swarmconfig")
	local f = fs.open("startup","w")
	f.write("shell.run('swarm.lua')")
	f.close()
	print("Installation complete; starting miner")
	shell.run("swarm.lua")
end
]]

os.loadAPI(".sq/config.lua")
os.loadAPI(".sq/json.lua")

for k,v in pairs(_G) do
  print(k)
  print(v)
end

if fs.exists("disk/.swarmconfig") then fs.delete("disk/.swarmconfig") end
config.init("disk/.swarmconfig")
term.clear()
term.setCursorPos(1,1)
print("Please enter the address of the host server below.")
write("> ")
local host = read()
config.set("host",host)
print("What should the name of the swarm be?")
write("> ")
local name = read()
config.set("swarmname",name)
print("How wide should the quarry be, in blocks?")
write("> ")
local w = tonumber(read()) or 10
print("How long should the quarry be, in blocks?")
write("> ")
local h = tonumber(read()) or 10
print("How much extra fuel should turtles keep when getting fuel?")
print("The higher the number, the more efficient the fuel usage, but higher fuel requirements. Defaults to 250.")
write("> ")
local fb = tonumber(read()) or 250
config.set("fuelbuffer",fb)
config.set("fuelspare",25)
print("Contacting server...")
local h = http.get(host .. "/swarm/" .. name .. "/create?w=" .. w .. "&h=" .. h)
if h then
	local response = json.decode(h.readAll())
	if response.success then
		print("Success!")
		print(response.shafts .. " shafts will be mined.")
		for i,v in ipairs(copyfiles) do
			if fs.exists("disk/"..v) then
				fs.delete("disk/"..v)
			end
			fs.copy(".sq/"..v,"disk/"..v)
		end
		config.set("dropoff",{x=0,y=64,z=-3,f=2})
		config.set("block_blacklist",blacklist)
		config.set("autoname",true)
		if fs.exists("disk/startup") then fs.delete("disk/startup") end
		local f = fs.open("disk/startup","w")
		f.write(deploy_code)
		f.close()
		print("Setup complete!")
		print("Please follow the instructions in the forum thread to deploy miners using the disk.")
	else
		print("Oh no!")
		print("An error occurred!")
		print("Error: " .. response.error)
	end
else
	print("Hmm, I can't reach the server.")
	print("Are you sure you set it up correctly and it is running?")
end
