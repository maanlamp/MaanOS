local Inspector = {
	builtinMethods = {"prototype", "constructor"};
};

function Inspector.typeof (value)
	local ok, returnType = pcall(function () return value.prototype.private.className end);
	if ok then return returnType end;
	return type(value);
end

function Inspector.tableContains (table, value)
	for k, v in pairs(table) do
		if k == value or v == value then return true end;
	end
end

function Inspector.getAdress (value)
	return tostring(value):gsub("%w+: ([a-zA-Z0-9]+)", "%1");
end

function Inspector.getMethodName (method)
	-- Property name, anonymous or adress?
	return Inspector.getAdress(method);
end

function Inspector.inspect (toInspect, maxDepth, currentDepth)
	if not maxDepth then maxDepth = 0 end;
	if not currentDepth then currentDepth = 0 end;
	local str = ((Inspector.typeof(toInspect):gsub("^%l", string.upper).." ").."{ "):gsub("Table ", ""); -- add prototype, but skip it if it's "Table" because that's obvious.
	for key, value in pairs(toInspect) do
		(function () -- Setup for continue-like return
			if key:sub(1, 2) == "__" or Inspector.tableContains(Inspector.builtinMethods, key) then return end; -- Don't list private entries or the prototype (continue)
			local stringifiedValue;
			local _type = type(value);
			if _type == "table" then
				stringifiedValue = (currentDepth < maxDepth) and Inspector.inspect(value, maxDepth, currentDepth + 1) or ("[ "..Inspector.typeof(value):gsub("^%l", string.upper)..": "..Inspector.getAdress(value).." ]");
			elseif _type == "string" then
				stringifiedValue = "\""..value.."\"";
			elseif _type == "function" then
				stringifiedValue = "[ Function: "..Inspector.getMethodName(value).." ]";
			else
				stringifiedValue = tostring(value);
			end
			str = str.."\n"..("  "):rep(currentDepth + 1)..key..": "..stringifiedValue..",";
		end)();
	end
	return str:gsub(",$", "\n")..("  "):rep(currentDepth).."}";
end

return inspect;