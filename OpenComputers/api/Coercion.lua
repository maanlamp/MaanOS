local Coercion = {};

function Coercion.toboolean (value)
	if value == true or value == false then return value end;
	return not not value;
end

return Coercion;