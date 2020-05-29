-- Get kernel up and running ASAP, no fancy stuff.
-- Accessible namespaces and methods: https://ocdoc.cil.li/tutorial:custom_oses

local address = computer.getBootAddress();

local function go (...)
	return component.invoke(address, ...);
end

local function try (f, ...)
	local ok, dataOrError = pcall(f, ...);
	
	if ok then
		return dataOrError, nil;
	end
	return nil, dataOrError;
end

local function read (file)
	local handle = go("open", file);
	
	if handle == nil then
		error("\""..file.."\" does not exist.");
	end

	local buffer = "";
	repeat
		local data = go("read", handle, math.huge);
		buffer = buffer..(data or "");
	until not data;

	go("close", handle);
	return buffer;
end

local function sleep (seconds)
	local till = os.clock() + seconds;
	repeat until os.clock() > till;
end

local function crash (reason, shutdown)
	local gpu = component.proxy(component.list("gpu")());
	local vw, vh = gpu.getResolution();
	gpu.setBackground(0xFFFFFF);
	gpu.fill(1, 1, vw, vh, " ");
	gpu.setForeground(0x909090);
	gpu.set(5, 5, "KERNEL CRASH");
	gpu.set(5, 6, "Uh oh :(");
	gpu.setForeground(0xCCCCCC);
	gpu.set(5, 8, ({reason:gsub("^%[string %\"(.-)%\"%]", "%1")})[1]);

	local times = 3;
	repeat
		computer.beep()
		times = times - 1;
	until times == 0;

	sleep(5);

	if shutdown then
		computer.shutdown();
	end
end

local function run (kernelFile, ...)
	-- 1. read kernel file
	local data, err = try(read, kernelFile);
	if err then crash(err) end

	-- 2. load kernel file
	local kernel, err = try(load, data, "kernel.lua", "bt");
	if err then crash(err) end

	-- 3. Set up kernel env
	local env = {};
	function env.using (name)
		local ext = ".lua";
		if name:sub(-#ext) ~= ext then
			name = name..ext;
		end
		env[name] = try(load(read(name), "DONKEY", "bt", env));
	end

	-- 4. try call loaded kernel
	-- TODO: How and where could we allow
	--       updating of the kernel here?
	local _, err = try(kernel);
	if err then crash(err, true) end

	crash("Kernel somehow returned? "..tostring(_), true);
end

run"./kernel.lua";