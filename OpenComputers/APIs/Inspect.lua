function contains (table, value)
	for k, v in pairs(table) do
		if k == value or v == value then return true end;
	end
end

function getAdress (value)
	return tostring(value):gsub("%w+: (.+)", "%1");
end

function getMethodName (method)
	-- Property name, anonymous or adress?
	return getAdress(method);
end

function inspect (self, maxDepth, currentDepth)
	local builtinMethods = {"prototype", "constructor"};
	if not maxDepth then maxDepth = 0 end;
	if not currentDepth then currentDepth = 0 end;
	local str = (self.private and self.private.className and self.private.className.." " or "").."{ "; -- All classes should have private.className attribute.
	for key, value in pairs(self) do
		(function () -- Setup for continue-like return
			if key:sub(1, 2) == "__" or contains(builtinMethods, key) then return end; -- Don't list private entries or the prototype (continue)
			local stringifiedValue;
			local _type = type(value);
			if _type == "table" then
				stringifiedValue = (currentDepth < maxDepth) and inspect(value, maxDepth, currentDepth + 1) or ("[ "..(value.private and value.private.className or "Table")..": "..getAdress(value).." ]");
			elseif _type == "string" then
				stringifiedValue = "\""..value.."\"";
			elseif _type == "function" then
				stringifiedValue = "[ Function: "..getMethodName(value).." ]";
			else
				stringifiedValue = tostring(value);
			end
			str = str.."\n"..("  "):rep(currentDepth + 1)..key..": "..stringifiedValue..",";
		end)();
	end
	return str:gsub(",$", "\n")..("  "):rep(currentDepth).."}";
end

return inspect;