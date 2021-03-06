local Array = {};

function Array.isArray (value)
	return getmetatable(value) == Array;
end

function Array.from (_table)
	if Array.isArray(_table) then return _table end;
	--Convert all keys to their values and then remove the values.
	local tmp = {};
	setmetatable(tmp, Array);
	for i, value in ipairs(_table) do
		tmp[i] = value;
	end
	return tmp;
end

Array._MEMBERS = Array.from{
	length = 0;
};

function Array:includes (value)
	return self:some(function(val) return val == value end);
end

function Array:__index (key) --Get
	if self._MEMBERS:includes(key) then
		return (type(self._MEMBERS[key]) == "function")
			and self._MEMBERS[key](self)
			or self._MEMBERS[key];
	else
		return Array; --MUI IMPORTANTE!! <- Als array geen gecallde method heeft, zoek in de 'prototype'/metatable
	end
end;

function Array:__newindex (key, value) --Set
	if self._MEMBERS:includes(key) then
		self._MEMBERS[key] = value;
	else
		return Array; --MUI IMPORTANTE!! <- Als array geen gecallde method heeft, zoek in de 'prototype'/metatable
	end
end;

function Array:__tostring ()
	return self:toString()
end;

function Array:forEach (lambda)
	for i, value in ipairs(self) do
		lambda(value, i, self);
	end
end

function Array:clone ()
	if (table.unpack) then
		return Array.from{ table.unpack(self) };
	else
		local clone = {} ;
		self:forEach(function (value, i)
			clone[i] = value;
		end);
		return Array.from(clone);
	end
end

function Array:toString ()
	local returnString = "[ ";
	for i = 1, self:length() do
		if type(self[i]) == "table" then
			returnString = returnString..tostring(self[i])..", ";
		else
			local checkForNil = (self[i] == nil)
				and "nil";
			local checkForString = (type(self[i]) == "string")
				and string.format("%q", self[i]);
			local stringifiedValue = checkForNil
				or checkForString
				or self[i];
			returnString = returnString..stringifiedValue..", ";
		end
	end
	return ({(returnString.."]"):gsub(", ]", " ]")})[1];
end

function Array:map (lambda)
	local clone = self:clone();
	clone:forEach(function (value, i, clone)
		clone[i] = lambda(value, i, self);
	end);
	return clone;
end

function Array:length ()
	return #self;
	--return self:reduce(function (total) return total + 1 end, 0);
end

function Array:push (value)
	--support multiple elements.
	self[self:length() + 1] = value; --table.insert(self, value); <- Slower method.
	return self:length();
end

function Array:pop ()
	return table.remove(self);
end

function Array:first (count)
	return self:slice(1, count or 1);
end

function Array:last (count)
	return self:slice(-(count or 1), self:length());
end

function Array:shift ()
	return table.remove(self, 1);
end

function Array:unshift (value)
	--support multiple elements.
	table.insert(self, 1, value);
	return self:length();
end

function Array:every (lambda)
	for i, value in ipairs(self) do
		if not lambda(value, i, self) then return false end;
	end
	return true;
end

function Array:some (lambda)
	for i, value in ipairs(self) do
		if lambda(value, i, self) then return true end;
	end
	return false;
end

function Array:fill (value)
	self:forEach(function (_, i)
		self[i] = value;
	end);
	return self;
end

function Array:filter (lambda)
	local returnArray = Array.from{};
	self:forEach(function (val, i, this)
		if lambda(val, i, this) then returnArray:push(val) end;
	end);
	return returnArray;
end

function Array:reduce (lambda, initial)
	local i = 1;
	local acc;
	if not initial then
		acc = self[1];
		i = 2;
	end
	for index = i, self:length() do
		local val = self[index];
		acc = lambda(acc, val, index, self);
	end
	return acc;
end

function Array:slice (from, to)
	local returnArray = Array.from{};
	if from < 0 then from = self:length() + from + 1 end;
	if not to then to = self:length() end;
	if to < 0 then to = self:length() + to + 1 end;
	for i = from, to do
		returnArray:push(self[i]);
	end
	return returnArray;
end

function Array:splice (from, to)
	local returnArray = Array.from{};
	for i = from, to do
		returnArray:push(table.remove(self, from));
	end
	return returnArray;
end

function Array:clear ()
	return self:fill(nil);
end

function Array:sum ()
	return self:reduce(function (acc, val) return acc+val end);
end

function Array:average ()
	return self:sum() / self:length();
end

function Array:sort (lambda)
	return table.sort(self:clone(), lambda);
end

function Array:median ()
	local length = self:length();
	local sortedArray = self:sort();
	local half = math.floor(length / 2);
	if length % 2 then
		return sortedArray[half];
	else
		return (sortedArray[half-1] + sortedArray[half]) / 2;
	end
end

function Array:find (lambda)
	for i, val in ipairs(self) do
		if lambda(val, i, self) == true then return self[i] end;
	end
	-- UNTESTED!!!
end

function Array:findIndex (lambda)
	for i, val in ipairs(self) do
		if lambda(val, i, self) == true then return i end;
	end
	-- UNTESTED!!!
end

--METAMETHODS
function Array.__eq (this, other)
	if this:length() ~= other:length() then return false end;
	for i = 1, this:length() do
		if this[i] ~= other[i] then return false end;
	end
	return true;
end
function Array.__lt (this, other)
	--if array
	return this:sum() < other:sum();
	--if number self:every < other
end
function Array.__le (this, other)
	--if array
	return this:sum() <= other:sum();
	--if number self:every <= other
end
function Array.__add (this, other)
	--if array go through other and add other[i] to self[i];
	--if number map add to all indexes
end
function Array.__sub (this, other)
	--do something
end
function Array.__mul (this, other)
	--do something
end
function Array.__div (this, other)
	--do something
end
function Array.__mod (this, other)
	--do something
end
function Array.__unm (this, other)
	--do something
end
function Array.__concat (this, other)
	--if array push other to this then :toString()
end
function Array.__pow (this, other)
	--do something
end

return Array;