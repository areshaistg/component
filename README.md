# Component

Roblox Component Module that integrates CollectionService Tags and Attributes together. WIth typesafe (albeit runtime only) attributes, and quick autocompletion.

Highly inspired by sleitnick's Component module from [RbxUtil](https://github.com/Sleitnick/RbxUtil).

## Installing

### 1. Wally

Simply add `Component = "areshaistg/component@0.1.0"` to `wally.toml` in your project.

### 2. Roblox Command Line

This method is borrowed from eveara's [Promise](https://eryn.io/roblox-lua-promise/docs/Installation) implementation.

1. In Roblox Studio, select the folder where you keep your third party modules / utilities.
2. Run this in the command bar:

```lua
local Http = game:GetService("HttpService")
local HttpEnabled = Http.HttpEnabled
Http.HttpEnabled = true
local m = Instance.new("ModuleScript")
m.Parent = game:GetService("Selection"):Get()[1] or game:GetService("ServerScriptService")
m.Name = "Component"
m.Source = Http:GetAsync("https://raw.githubusercontent.com/areshaistg/component/main/lib/init.lua")
game:GetService("Selection"):Set({m})
Http.HttpEnabled = HttpEnabled
```

# Usage

### Basic Component

Creating components with this module can be done quickly.

```lua
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local Component = require(Packages.Component)

local MyComponent = Component.Create({ Tag = "MyTag" })
function MyComponent.Start(self)
  print("Start")
end

function MyComponent.Stop(self)
  print("Stop")
end

Component.Register(MyComponent)
```

Components can use the `--!strict` inference mode. If you are using [Trove](https://sleitnick.github.io/RbxUtil/api/Trove/) (which I highly recommend), it can be set up like this:

```lua
function MyComponent.Start(self)
  self.Trove = Trove.new()
  self.Trove:Add(function()
    print("Cleanup")
  end)
end

function MyComponent.Stop(self)
  self.Trove:Destroy()
end
```

If you were writing along, you would see that the Luau LSP knows that `self.Trove` is a Trove, and not just some random type. I find this useful when using custom instances (like Trove).

If you have an instance that has the component, you can get the component instance from another script using the `.From` function

```lua
local MyComponent = require(path.to.MyComponent)
local ci = MyComponent.From(workspace.Model)
```

Just make sure that the instance is already constructed

### Attributes

Ever since attributes were added to Roblox, I've always preferred to use it instead of Value objects (which I already didn't like). An attributes map must be provided to `Component.Create` for attributes to be used. This makes sure that the attributes actually exist and are the correct type. Its recommended using [t](https://github.com/osyrisrblx/t) for this, instead of making your own typecheckers, unless you need something more complex.

```lua
local MyComponent = Component.Create({
  ...
  Attributes = {
    Message = t.string,
  },
})
```

Inside component instances, you can easily access the `Attributes` table. Modifying the members will also apply to the instance.

```lua
function MyComponent.Start(self)
  print(self.Attributes.Message)
  self.Attributes.Message = "Hello world!"
  print(self.Attributes.Message)
end
```

### Hierarchy

I highly recommend using [t](https://github.com/osyrisrblx/t) for this, as it is what its specifically made for, but you could still use any other function that takes the instance.

You just use a typecheck or a function to the Hierarchy option

```lua
local MyComponent = Component.Create({
  ...
  Hierarchy = t.instance("Model", {
    Part = t.instance("Part")
  }),
})
```

The typecheck is called on a component instance that is about to be created. The typecheck must return a true, or else the component wouldn't be created.

### User-defined Functions

Component instances are just basic tables (other than the Attributes table), so creating functions are pretty simple.

```lua
function MyComponent.Foo(self)
	print(self.Instance:GetFullName())
end

function MyComponent.Start(self)
  MyComponent.Foo(self)
end
```

Once you look closely, it doesn't resemble anything like the common OOP paradigm you see on Roblox with metatables. This is highly inspired from the way C uses basic structs and functions.

Calling functions from another script should be as simple as:

```lua
local MyComponent = require(path.to.MyComponent)
local ci = MyComponent.From(workspace.Model)
MyComponent.Foo(ci)
```
