local service = {};

function service:register (name, service)
	self[name] = service;
	return self;
end

function service:locate (name)
	-- TODO: use Maybe
	return self[name];
end

return service;