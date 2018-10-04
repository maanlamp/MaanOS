local coercion = {};

function coercion.toboolean (value)
	if value == true or value == false then return value end;
	return not not value;
end

return coercion