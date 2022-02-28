-- Options

newoption({
  trigger = "to",
  value = "path",
  default = "workspace-%{_ACTION}",
  description = "Set the output location for the generated files"
})

-- Workspace config

workspace("tests")
  configurations({
    "Debug",
    "Release",
  })
  vpaths({
    ["include"] = {"**.h", "**.hpp"},
    ["src"] = {"**.c", "**.cpp"},
    ["lua"] = {"**.lua"},
  })
  location(_OPTIONS["to"])
  targetdir("%{wks.location}/bin/%{cfg.shortname}")
  objdir("%{wks.location}/obj/%{cfg.shortname}/%{prj.name}")

   -- supported platforms
  filter("system:windows")
    platforms({
      "amd64",
      "x86",
    })
  filter("system:linux")
    platforms({
      "native",
    })
  filter({"system:macosx"})
    platforms({
      "Universal",
    })
    buildoptions({
      "-arch arm64",
      "-arch x86_64",
    })
    linkoptions({
      "-arch arm64",
      "-arch x86_64",
    })
  filter({})

  -- languages standard
  filter("action:not vs*")
    cdialect("gnu11")
    cppdialect("gnu++11")
  filter("action:vs*")
    cdialect("C11")
    cppdialect("C++11")
  filter({})

  filter("language:C++")
    rtti("Off")
    exceptionhandling("Off")
  filter("")
    filter("kind:*") -- projects location
    location("%{wks.location}/projects")
  filter("kind:StaticLib") -- static libs location
    targetdir("%{wks.location}/static_libs/%{cfg.shortname}")
  filter("kind:SharedLib")
    pic("On")
  filter("configurations:Debug")
    symbols("On")
    defines({"_DEBUG"})
  filter("configurations:Release")
    symbols("Off")
    optimize("Speed")
    defines({"NDEBUG"})
    flags({"LinkTimeOptimization"})
  filter({})

-- Custom projects

-- Projects from JSON

local projectFiles = os.matchfiles("./**premake.json")
local usages = {}

-- parse usages
for _, file in ipairs(projectFiles) do
  local jsonStr = io.readfile(file)
  local p, err = json.decode(jsonStr)

  if err ~= nil then
    premake.error(file .. ":\n" .. err)
  end

  local usage = p.usage
  if usage ~= nil then
    usage.path = path.getdirectory(file)
    usages[p.project.name] = usage
  end
end

-- parse projects
for _, file in ipairs(projectFiles) do
  local jsonStr = io.readfile(file)
  local p, err = json.decode(jsonStr)

  if err ~= nil then
    premake.error(file .. ":\n" .. err)
  end

  p = p.project
  local name = p.name
  if name ~= nil then
    basePath = path.getdirectory(file)
    project(name)
    kind(p.kind)
    language(p.language)
    -- custom flags (TODO)

    -- includedirs
    local prjInc = p.includedirs
    if prjInc ~= nil then
      for _, inc in ipairs(prjInc) do
        includedirs(path.join(basePath, inc))
      end
    end
    -- add files
    local prjFiles = p.files
    if prjFiles ~= nil then
      for _, f in ipairs(prjFiles) do
        files(path.join(basePath, f))
      end
    end
    -- links
    local prjLinks = p.links
    if prjLinks ~= nil then
      links(prjLinks)
    end
    -- uses
    local uses = p.uses
    if uses ~= nil then
      for _, depName in ipairs(uses) do
        local dep = usages[depName]
        if dep ~= nil then
          -- includes
          local depInc = dep.includedirs
          if depInc ~= nil then
            for _, inc in ipairs(depInc) do
              includedirs(path.join(dep.path, inc))
            end
          end
          -- links
          links(dep.links)
          -- platform links
          local pl = "links_" .. os.target()
          links(dep[pl])
        end
      end
    end
  end
end
