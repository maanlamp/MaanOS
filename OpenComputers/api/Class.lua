local Inspector = require("../Inspect.lua");

local Class = {
	private = {
		className = "Class";
	};
	public = {};
	toString = Inspector.inspect;
};
Class.__index = Class;

function Class.new (name, constructor)
	local instance = {};
	setmetatable(instance, Class);
	instance.private.className = name;
	instance.prototype = getmetatable(instance);
	if constructor then
		instance.constructor = constructor;
		instance:constructor();
	end
	return instance;
end

--[[
class Object {
	constructor () {
		this.foo = "bar";
		this.baz = "quux";
		this.test = {
			hi = 3;
			test = {};
		};
	}

	idk () {
		-- Nothing
	}
}

local object = new Object();
]]--
local object = Class.new("Object", function (this)
	this.foo = "bar";
	this.baz = "quux";
	this.test = Class.new("Test", function (this)
		this.hi = 3;
		this.kont = Class.new("Kont", function (this)
			this.isCool = true;
		end);
	end);
	this.idk = function () end;
end);

print(object:toString());