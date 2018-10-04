local args = {...};
local inet = require("internet");

local source;
local ok, err = pcall(function()
	local file = io.open(args[1]);
	source = file:read("*all");
	file:close();
end);

local tokens;
if ok then
	tokens = {};
	local allChunks = "";
	for chunk in inet.request("http://localhost:1337", source) do
		allChunks = allChunks..chunk;
	end
	for tokenString in allChunks:gmatch([[{.-}]]) do
		local token = {};
		token.lexeme = tokenString:match([["lexeme":"(.-)"]]);
		token.type = tokenString:match([["type":"(.-)"]]);
		table.insert(tokens, token);
	end
else
	print("\nError: "..args[1].." does not exist, or cannot be read.\n");
end

return tokens;