local tablex = require("pl.tablex")

local dzen = require("dzen")

local xdotool = require("xdotool")

local wmii = require("wmii")

local x11 = require("x11")

local grabkey = require("grabkey")

require("event_handler_registry")

require("command_registry")

require("wmii_events")

-------------------------------------------------
-------------------------------------------------
local commands = {}

local test = {}
test.interactive = true
test.arguments = {}
setmetatable(test, test)
function test:__call()
   print("Called test:__call")
end

local test2 = {}
test2.interactive = true
test2.arguments = {}
setmetatable(test2, test2)
function test2:__call()
   print("Called test2:__call")
end

-- refresh the list of commands by looking through the
-- module for objects with the `interactive' property
function refreshCommands()
   commands = {}
   local i = 1
   while true do
	  local n, v = debug.getlocal(2, i)
	  if not n then break end
	  if type(v) == "table" and v.interactive then
		 commands[n] = v
	  end
	  i = i + 1
   end
end
refreshCommands()

function lineEditReplace(replaceString)
   return function(x)
	  return x .. replaceString
   end
end

local lineEditCommands = {}
lineEditCommands["BackSpace"] = function (text)
   return text:gsub(".$", "")
end
lineEditCommands["grave"] = lineEditReplace("`")
lineEditCommands["asciitilde"] = lineEditReplace("~")
lineEditCommands["exclam"] = lineEditReplace("!")
lineEditCommands["at"] = lineEditReplace("@")
lineEditCommands["numbersign"] = lineEditReplace("#")
lineEditCommands["dollar"] = lineEditReplace("$")
lineEditCommands["percent"] = lineEditReplace("%")
lineEditCommands["asciicircum"] = lineEditReplace("^")
lineEditCommands["ampersand"] = lineEditReplace("&")
lineEditCommands["asterisk"] = lineEditReplace("*")
lineEditCommands["parenleft"] = lineEditReplace("(")
lineEditCommands["parenright"] = lineEditReplace(")")
lineEditCommands["minus"] = lineEditReplace("-")
lineEditCommands["underscore"] = lineEditReplace("_")
lineEditCommands["equal"] = lineEditReplace("=")
lineEditCommands["plus"] = lineEditReplace("+")
lineEditCommands["backslash"] = lineEditReplace("\\")
lineEditCommands["bar"] = lineEditReplace("|")
lineEditCommands["slash"] = lineEditReplace("/")
lineEditCommands["period"] = lineEditReplace(".")
lineEditCommands["greater"] = lineEditReplace(">")
lineEditCommands["less"] = lineEditReplace("<")
lineEditCommands["comma"] = lineEditReplace(",")
lineEditCommands["semicolon"] = lineEditReplace(";")
lineEditCommands["colon"] = lineEditReplace(":")
lineEditCommands["bracketleft"] = lineEditReplace("[")
lineEditCommands["bracketright"] = lineEditReplace("]")
lineEditCommands["braceleft"] = lineEditReplace("{")
lineEditCommands["braceright"] = lineEditReplace("}")
lineEditCommands["space"] = lineEditReplace(" ")

local keyBindings = {}

keyBindings["w"] = function()
   print("You typed `w'!!!")
end

keyBindings["C-c x x x"] = function()
   os.execute("chromium http://luaposix.github.io/luaposix/docs/index.html")
end

keyBindings["Mod4-i"] = function()
   dzen:start()
   local command = ""
   grabkey:start()
   for k in grabkey:lines() do
	  if k == "Return" then
		 -- TODO make this able to run arbitrary code
		 grabkey:kill()
		 if commands[command] then
			commands[command]()
		 end
		 break
	  elseif lineEditCommands[k] then
		 command = lineEditCommands[k](command)
	  elseif #k == 1 then
		 command = command .. k
	  end
	  local titleText1 = command:gsub("(^)", "%1%1")
	  dzen:text("^cs()")
	  for cmd in tablex.sort(commands) do
		 if command ~= "" and cmd:match(command) then
			local dispText = cmd:gsub("(^)", "^^")
			dispText = dispText:gsub("(" .. titleText1 .. ")", "^fg(#859900)%1^fg()")
			dzen:text(dispText)
		 end
	  end

	  local titleText2
	  if titleText1:match("(^^)$") then
		 titleText2 = titleText1:gsub("(^^)$", "^fg(#cb4b16)%1")
	  else
		 titleText2 = titleText1:gsub("(.)$", "^fg(#cb4b16)%1")
	  end
	  dzen:title(titleText2)
   end
   dzen:stop()
end

local keyBuf = ""

-- event loop
local eventStream = io.popen("./events.sh")
for ev in eventStream:lines() do
   if ev:match("wmii: Key Mod4.o") then
	  keyBuf = ""
	  grabkey:start()
	  for k in grabkey:lines() do
		 if keyBuf == "" then
			keyBuf = k
		 else
			keyBuf = keyBuf .. " " .. k
		 end
		 if #keyBuf > 20 then
			print("Long key-sequence. cancelling " .. keyBuf)
			break
		 end
		 if keyBindings[keyBuf] then
			keyBindings[keyBuf]()
			break
		 end
	  end
	  keyBuf = ""
	  grabkey:kill()
   elseif ev:match("wmii: Key ") then
	  local key = ev:gsub("wmii: Key ", "")
	  if keyBuf == "" then
		 keyBuf = key
	  else
		 keyBuf = keyBuf .. " " .. key
	  end
	  if #keyBuf > 20 then
		 print("Long key-sequence. cancelling " .. keyBuf)
		 keyBuf = ""
	  end
	  if keyBindings[keyBuf] then
		 keyBindings[keyBuf]()
		 keyBuf = ""
	  end
   else
	  -- TODO first match to ':' has to be non-greedy
	  local a = ev:gmatch("([-%w]*):%s+(.*)$")
	  local eventType, eventData = a()
	  eventHandle(eventType, eventData)
   end
end

eventStream:close()
