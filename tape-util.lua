local args = { ... }

local function getFile(url, fname)
	local r = http.get(url, nil, true)

	if not r then
		print("Error: Could not get file")
		return
	end
	if (r.getResponseCode() == 301 or r.getResponseCode() == 302) then
		-- print("Redirected to " .. r.getResponseHeaders()["Location"])
		local loc = r.getResponseHeaders().Location
		r.close()
		return getFile(loc, fname)
	end
	if (r.getResponseCode() == 200) then
		-- print("Creating file " .. fname)
		local f = fs.open(fname, "wb")
		if f then
			f.write(r.readAll())
			f.close()
			return 1
		else
			print("Error: Could not open file")
		end
	else
		print("Error: status code " .. r.getResponseCode())
	end
end

local function helpText()
	print("Usage:")
	print(" - 'tape-util' to display this help text")
	print(" - 'tape-util loop' to loop a cassette tape")
	print(" - 'tape-util dl [github dir]' to write github directory to tape")
	return
end

--Returns true if position 1 away is zero
local function seekNCheck()
	--seek 1 and check
	tape.seek(1)
	print("Seeking 1...")
	if tape.read() == 0 then
		return true
	else
		return false
	end
end

--Checks multiple bits into distance to make sure it is actual end of track, and not just a quiet(?) part
local function seekNCheckMultiple()
	for i = 1, 10 do
		if seekNCheck() == false then
			return false
		end
	end
	return true
end

-- this could be made into a more efficient algo?
local function findTapeEnd(...)
	local accuracy = 100
	print("Using accuracy of " .. accuracy)

	local tapeSize = tape.getSize()
	print("Tape has size of: " .. tapeSize)
	tape.seek( -tapeSize) -- rewind tape
	local runningEnd = 0

	for i = 0, tapeSize do --for every piece of the tape
		os.queueEvent("randomEvent") -- timeout
		os.pullEvent() -- prevention
		tape.seek(accuracy) --seek forward one unit (One takes too long, bigger values not as accurate)
		if tape.read() ~= 0 then --if current location is not a zero
			runningEnd = i * accuracy --Update Running runningEnd var. i * accuracy gets current location in tape
			print("End Candidate: " .. runningEnd)
		elseif seekNCheckMultiple() then --check a few spots away to see if zero as well
			return runningEnd
			--else return runningEnd --otherwise, (if 0) return runningEnd
		end --end if
	end
end

local function looper(...)
	print("Initializing...")
	--find tape end
	print("Locating end of song...")
	local endLoc = findTapeEnd()
	print("End of song at position " .. endLoc .. ", or " .. endLoc / 6000 .. " seconds in\n")
	print("Starting Loop! Hold Ctrl+T to Terminate")
	while true do
		tape.seek( -tape.getSize())
		tape.play()
		print("... Playing")
		sleep(endLoc / 6000)
		print("Song Ended, Restarting...")
	end
	--play tape until
end

--Credit to the writers of Computronics for the bulk of wrtieTapeModified() function, see README for more info.
local function writeTape(relPath)
	local file, msg, _, y, success
	local block = 8192 --How much to read at a time

	tape.stop()

	local path = shell.resolve(relPath)
	local bytery = 0 --For the progress indicator
	local filesize = fs.getSize(path)
	-- print("Path: " .. path)
	file, msg = fs.open(path, "rb")
	if not fs.exists(path) then msg = "file not found" end
	if not file then
		printError("Failed to open file " .. relPath .. (msg and ": " .. tostring(msg)) or "")
		return
	end

	print("Writing...")

	_, y = term.getCursorPos()

	if filesize > tape.getSize() then
		term.setCursorPos(1, y)
		printError("Error: File is too large for tape, shortening file")
		_, y = term.getCursorPos()
		filesize = tape.getSize()
	end

	repeat
		local bytes = {}
		for i = 1, block do
			local byte = file.read()
			if not byte then break end
			bytes[#bytes + 1] = byte
		end
		if #bytes > 0 then
			if not tape.isReady() then
				io.stderr:write("\nError: Tape was removed during writing.\n")
				file.close()
				return
			end
			term.setCursorPos(1, y)
			bytery = bytery + #bytes
			term.write("Read " .. tostring(math.min(bytery, filesize)) .. " of " .. tostring(filesize) .. " bytes...")
			for i = 1, #bytes do
				tape.write(bytes[i])
			end
			sleep(0)
		end
	until not bytes or #bytes <= 0 or bytery > filesize
	file.close()
	tape.stop()
	--tape.seek(-tape.getSize()) --MODIFIED same reaosn as above...
	tape.stop() --Just making sure
	print("\nDone.")
end

local function tapeDl(url)
	local page = http.get(url)
	local pageHTML = page.readAll()
	page.close()

	local dfpwmFiles = {}
	for file in pageHTML:gmatch("href%s*=%s*[\"']([^\"'>]*%.dfpwm)[\"']") do
		if file:sub(1, 1) == "/" then
			file = "https://github.com" .. file
		end
		file = file:gsub("blob", "raw")
		table.insert(dfpwmFiles, file)
	end

	for file in pairs(dfpwmFiles) do
		-- Parse filename from URL and decode
		local fileName = dfpwmFiles[file]:match("([^/]+)$")
		fileName = fileName:gsub("%%(%x%x)", function(hex) return string.char(tonumber(hex, 16)) end)
		print("Downloading " .. fileName)
		if getFile(dfpwmFiles[file], "/tmp/temp_dl.dfpwm") then
			writeTape("/tmp/temp_dl.dfpwm")
		end
	end
	tape.seek( -tape.getSize())
end

-- Main
tape = peripheral.find("tape_drive")
if not tape then
	print("This program requires a tape drive to run.")
	return
end
if args[1] == "loop" then
	looper()
elseif args[1] == "dl" then
	if args[2] ~= nil then
		print("running tapeDl")
		tape.seek( -tape.getSize())
		tapeDl(args[2])
	end
else
	helpText()
end
