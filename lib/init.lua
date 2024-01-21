--!strict

-- [[ Services ]] ----------------------------------------
local CollectionService = game:GetService("CollectionService")

-- [[ Types ]] ----------------------------------------
type Typechecker = (any) -> (boolean, string?)

-- [[ Attribute Metatable ]] ----------------------------------------
type AttributeMap = { [string]: Typechecker }
type AttributeTable = { __a: AttributeMap, __i: Instance, [string]: any }
local AttributeMetatable = {
	__index = function(t: AttributeTable, key: string)
		if t.__a[key] == nil then
			error("no attribute named " .. key, 2)
		end
		return t.__i:GetAttribute(key)
	end,

	__newindex = function(t: AttributeTable, key: string, val: any)
		if t.__a[key] == nil then
			error("no attribute named " .. key, 2)
		end

		local valid, msg = t.__a[key](val)
		if not valid and msg then
			error("cannot set attribute " .. key .. ": " .. msg, 2)
		elseif not valid then
			error("cannot set attribute " .. key, 2)
		end

		return t.__i:SetAttribute(key, val)
	end,
}

-- [[ Component ]] ----------------------------------------
local Component = {}

Component.AttachedComponents = {}

export type ComponentClass<T> = {
	Tag: string,
	Attributes: AttributeMap,

	Start: (ci: ComponentInstance & T) -> ()?,
	Stop: (ci: ComponentInstance & T) -> ()?,
}

export type ComponentInstance = {
	Tag: string,
	Attributes: typeof(setmetatable({} :: AttributeTable, AttributeMetatable)),
	Instance: Instance,
}

function Component.Create<T>(opts: {
	Tag: string,
	Attributes: AttributeMap?,
	Children: { [string]: Typechecker }?,
	IsA: string?,
}): ComponentClass<T>
	if type(opts.Tag) ~= "string" then
		error("Tag must be a string, got " .. typeof(opts.Tag), 2)
	end

	local self = {}

	self.Tag = opts.Tag
	self.Attributes = opts.Attributes or {}

	return self
end

function Initialize<T>(i: Instance, c: ComponentClass<T>): ComponentInstance
	local ci = {}

	ci.Tag = c.Tag
	ci.Instance = i
	ci.Attributes = setmetatable({ __a = c.Attributes, __i = i }, AttributeMetatable)

	if c.Start then
		c.Start(ci :: ComponentInstance & T)
	end

	return ci
end

function Component.Register<T>(c: ComponentClass<T>)
	local function onInstanceAdded(i: Instance)
		local ci = Initialize(i, c)
		Component.AttachedComponents[i] = ci
	end

	local function onInstanceRemoved(i: Instance)
		local ci = Component.AttachedComponents[i]
		if ci then
			if c.Stop then
				c.Stop(ci :: ComponentInstance & T)
			end
			Component.AttachedComponents[i] = nil
		end
	end

	for _, i in CollectionService:GetTagged(c.Tag) do
		task.spawn(onInstanceAdded, i)
	end
	CollectionService:GetInstanceAddedSignal(c.Tag):Connect(onInstanceAdded)
	CollectionService:GetInstanceRemovedSignal(c.Tag):Connect(onInstanceRemoved)
end

return Component
