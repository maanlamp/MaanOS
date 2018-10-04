--[[
	todo
		support self-referencing in tables
		switch
		trycatch
		//comment and /*comment*/
		automatically ObjectOrientify all functions (object.function(object,a,b,c) => object:function(a,b,c)) | setting
		make if-/forblocks actually work properly :/
		fix ternary
		MAYBE PROMISES / ASYNC AWAIT WITH SERVERS??? yeah that's a great idea definitely.
		or ||, and &&, not !
		arrow functions!!! a => b
]]--

local function Catch (pattern, replacement)
	return {pattern = pattern, replacement = replacement};
end

local constants = {
	DEFINEKEYWORD = "const",
	NEWLINE       = "\n"
}

local m2lua = {
	DEFINE = Catch(constants.DEFINEKEYWORD.." (.-) = (.-);?"..constants.NEWLINE, "--#defined \"%1\" as %2"..constants.NEWLINE),
	catches = {
		THIS           = Catch("this",                                "self"),
		APLUSEQUALSB   = Catch("([_%a][_%w]-) %+= ([_%a%w]-)",        "%1 = %1 + %2"),
		AMINUSEQUALSB  = Catch("([_%a][_%w]-) %-= ([_%a%w]-)",        "%1 = %1 - %2"),
		ATIMESEQUALSB  = Catch("([_%a][_%w]-) %*= ([_%a%w]-)",        "%1 = %1 * %2"),
		ADIVIDEEQUALSB = Catch("([_%a][_%w]-) /= ([_%a%w]-)",         "%1 = %1 / %2"),
		ANOTEQUALSB    = Catch("([_%a][_%w]-) != ([_%a%w]-)",         "%1 ~= %2"),
		APLUSPLUS      = Catch("([_%a][_%w]-)%+%+",                   "(function() %1 = %1 + 1 return %1 - 1 end)()"),
		AMINUSMINUS    = Catch("([_%a][_%w]-)%-%-",                   "(function() %1 = %1 - 1 return %1 + 1 end)()"),
		PLUSPLUSA      = Catch("%+%+([_%a][_%w]*)",                   "(function() %1 = %1 + 1 return %1 end)()"),
		MINUSMINUSA    = Catch("%-%-([_%a][_%w]*)",                   "(function() %1 = %1 - 1 return %1 end)()"),
		TERNARY        = Catch("%((.-)%) %? ([.%b\"\"%b'']-) : (.-)", "(function() return (%1 and {%2} or {%3})[1] end)()"),
		ELSEIF         = Catch("else if",                             "elseif"),
		FOROF          = Catch("for %((.-) of (.-)%)",                "for key, %1 in pairs(%2)"),
		FORIN          = Catch("for %((.-) in (.-)%)",                "for %1, value in ipairs(%2)"),
		FORGENERIC     = Catch("for %((.-);(.-);(.-)%)",              "GENERICFOR"),
		LITERAL        = Catch("(%b``)",                              Catch("^`(.*)`$", "[=========[%1]=========]")),
		PLACEHOLDER    = Catch("(%$%b{})",                            Catch("^${(.*)}$", "]=========]..%1..[=========[")),
		ARRAY          = Catch("[^%)%[_%a%w](%b[])",                  Catch("^%[(.*)%]$", "{%1}")),
		IFBLOCK        = Catch("if .-(%b{})",                         Catch("^{(.*)}$", "then %1 end")),
		--FORBLOCK       = Catch("for .-(%b{})",                        Catch("^{(.*)}$", "do %1 end")),
		--WHILEBLOCK     = Catch("while .-(%b{})",                      Catch("^{(.*)}$", "do %1 end")),
		FUNCTIONBLOCK  = Catch("function .-(%b{})",                   Catch("^{(.*)}$", "%1 end"))
	},
	userCatches = {}
}

function m2lua:compile (template, data)
	local replaceCount = 0;
	local function chunk (_table)
		for name, catch in pairs(_table) do
			if template:find(catch.pattern) then
				if type(catch.replacement) == "string" then
					print("Found "..name);
					template = template:gsub(catch.pattern, catch.replacement);
					replaceCount = replaceCount + 1;
				else
					while (template:match(catch.pattern)) do
						for pattern in template:gmatch(catch.pattern) do
							print("Found "..name);
  						local replacement = pattern:gsub(catch.replacement.pattern, catch.replacement.replacement);
  						template = template:gsub(pattern:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%0"), replacement);
  						replaceCount = replaceCount + 1;
  					end  
					end
				end
			end
		end
	end
	--Save definitions
	while template:find(self.DEFINE.pattern) do
		self:define(template:match(self.DEFINE.pattern));
		template = template:gsub(self.DEFINE.pattern, self.DEFINE.replacement);
		replaceCount = replaceCount + 1;
	end
	--Compile
	chunk(self.userCatches);
	chunk(data or self.catches);
	--Format template to style? (e.g. change \r\n to \n, \t to space*tabsize)
	return template, replaceCount;
end

function m2lua:define (pattern, replacement)
	--get {pattern and replacement} from string, then insert into self.userCatches
	if replacement == nil and pattern:find(constants.DEFINEKEYWORD) == 1 then
		replacement = pattern:gsub("^"..constants.DEFINEKEYWORD.." (.-) = (.-)$", "%2");
		pattern = pattern:gsub("^"..constants.DEFINEKEYWORD.." (.-) = (.-)$", "%1");
	end
	self.userCatches[pattern] = Catch(pattern, replacement);
end

local env = {...};
local ok, err = pcall(function ()
	local m = io.open(env[1], "r");
	local temp = "";
	for line in m:lines() do
		temp = temp..line.."\n";
	end
	m:close();
	local lua = io.open(env[2], "w");
	local compiled, subs = m2lua:compile(temp);
	lua:write(compiled);
	lua:close();
	print(subs.." substitutions made.");
end);
if ok then
	print("Succesfully compiled to "..env[2]);
else
	print("Whoops, something went wrong!")
	print(err);
end