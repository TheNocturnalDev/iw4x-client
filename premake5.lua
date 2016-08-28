-- Quote the given string input as a C string
function cstrquote(value)
	result = value:gsub("\\", "\\\\")
	result = result:gsub("\"", "\\\"")
	result = result:gsub("\n", "\\n")
	result = result:gsub("\t", "\\t")
	result = result:gsub("\r", "\\r")
	result = result:gsub("\a", "\\a")
	result = result:gsub("\b", "\\b")
	result = "\"" .. result .. "\""
	return result
end

-- Option to allow copying the DLL file to a custom folder after build
newoption {
	trigger = "copy-to",
	description = "Optional, copy the DLL to a custom folder after build, define the path here if wanted.",
	value = "PATH"
}

newoption {
	trigger = "no-new-structure",
	description = "Do not use new virtual path structure (separating headers and source files)."
}

newoption {
	trigger = "copy-pdb",
	description = "Copy debug information for binaries as well to the path given via --copy-to."
}

newoption {
	trigger = "ac-debug-detections",
	description = "Log anticheat detections."
}

newoption {
	trigger = "ac-debug-load-library",
	description = "Log libraries that get loaded."
}

newoption {
	trigger = "force-unit-tests",
	description = "Always compile unit tests."
}

newoption {
	trigger = "force-exception-handler",
	description = "Install custom unhandled exception handler even for Debug builds."
}

newoption {
	trigger = "force-minidump-upload",
	description = "Upload minidumps even for Debug builds."
}

newoption {
	trigger = "disable-bitmessage",
	description = "Disable use of BitMessage completely."
}

newaction {
	trigger = "version",
	description = "Returns the version string for the current commit of the source code.",
	onWorkspace = function(wks)
		-- get revision number via git
		local proc = assert(io.popen("git rev-list --count HEAD", "r"))
		local revNumber = assert(proc:read('*a')):gsub("%s+", "")
		proc:close()

		print(revNumber)
		os.exit(0)
	end
}

newaction {
	trigger = "generate-buildinfo",
	description = "Sets up build information file like version.h.",
	onWorkspace = function(wks)
		-- get revision number via git
		local proc = assert(io.popen("git rev-list --count HEAD", "r"))
		local revNumber = assert(proc:read('*a')):gsub("%s+", "")
		proc:close()

		-- get whether this is a clean revision (no uncommitted changes)
		proc = assert(io.popen("git status --porcelain", "r"))
		local revClean = 1
		local revCleanSuffix = ""
		if assert(proc:read('*a')) ~= "" then
			revClean = 0
			revCleanSuffix = " (unclean)"
		end
		proc:close()

		-- get current tag name (aka milestone for now)
		proc = assert(io.popen("git tag"))
		local tagName = assert(proc:read('*l'))

		-- get old version number from version.hpp if any
		local oldRevNumber = "(none)"
		local oldRevClean = 1
		local oldRevCleanSuffix = ""
		local oldVersionHeader = io.open(wks.location .. "/src/version.hpp", "r")
		if oldVersionHeader ~=nil then
			local oldVersionHeaderContent = assert(oldVersionHeader:read('*a'))
			oldRevNumber = string.match(oldVersionHeaderContent, "#define REVISION (%d+)")
			if oldRevNumber == nil then
				-- old version.hpp format?
				oldRevNumber = "(none)"
			end
			oldRevClean = string.match(oldVersionHeaderContent, "#define REVISION_CLEAN (%d+)")
			if oldRevClean == nil then
				-- old version.hpp format?
				oldRevClean = 1
			elseif oldRevClean ~= "1" then
				oldRevClean = 0
			else
				oldRevClean = 1
			end
		end
		if oldRevClean == 0 then
			oldRevCleanSuffix = " (unclean)"
		end

		-- generate version.hpp with a revision number if not equal
		if oldRevNumber ~= revNumber or oldRevClean ~= revClean then
			print ("Update " .. oldRevNumber .. oldRevCleanSuffix .. " -> " .. revNumber .. revCleanSuffix)
			local versionHeader = assert(io.open(wks.location .. "/src/version.hpp", "w"))
			versionHeader:write("/*\n")
			versionHeader:write(" * Automatically generated by premake5.\n")
			versionHeader:write(" * Do not touch, you fucking moron!\n")
			versionHeader:write(" */\n")
			versionHeader:write("\n")
			versionHeader:write("#define REVISION " .. revNumber .. "\n")
			versionHeader:write("#define REVISION_CLEAN " .. revClean .. "\n")
			versionHeader:write("#define MILESTONE " .. cstrquote(tagName) .. "\n")
			versionHeader:close()
		end
	end
}

depsBasePath = "./deps"

require "premake/bitmrc"
require "premake/fmt"
require "premake/json11"
require "premake/libcryptopp"
require "premake/libtomcrypt"
require "premake/libtommath"
require "premake/mongoose"
require "premake/pdcurses"
require "premake/protobuf"
require "premake/sqlite3"
require "premake/winksignals"
require "premake/zlib"

bitmrc.setup
{
	source = path.join(depsBasePath, "bitmrc"),
}
fmt.setup
{
	source = path.join(depsBasePath, "fmt"),
}
json11.setup
{
	source = path.join(depsBasePath, "json11"),
}
libcryptopp.setup
{
	source = path.join(depsBasePath, "bitmrc/libcryptopp"),
}
libtomcrypt.setup
{
	defines = {
		"LTC_NO_FAST",
		"LTC_NO_PROTOTYPES",
		"LTC_NO_RSA_BLINDING",
	},
	source = path.join(depsBasePath, "libtomcrypt"),
}
libtommath.setup
{
	defines = {
		"LTM_DESC",
	},
	source = path.join(depsBasePath, "libtommath"),
}
mongoose.setup
{
	source = path.join(depsBasePath, "mongoose"),
}
pdcurses.setup
{
	source = path.join(depsBasePath, "pdcurses"),
}
protobuf.setup
{
	source = path.join(depsBasePath, "protobuf"),
}
sqlite3.setup
{
	source = path.join(depsBasePath, "bitmrc/windows/sqlite3"),
}
winksignals.setup
{
	source = path.join(depsBasePath, "Wink-Signals"),
}
zlib.setup
{
	defines = {
		"ZLIB_CONST",
	},
	source = path.join(depsBasePath, "zlib"),
}

workspace "iw4x"
	location "./build"
	objdir "%{wks.location}/obj"
	targetdir "%{wks.location}/bin/%{cfg.buildcfg}"
	configurations { "Debug", "DebugStatic", "Release", "ReleaseStatic" }
	architecture "x32"
	platforms "x86"

	-- VS 2015 toolset only
	toolset "msc-140"

	configuration "windows"
		defines { "_WINDOWS", "WIN32" }

	configuration "Release*"
		defines { "NDEBUG" }
		flags { "MultiProcessorCompile", "Symbols", "LinkTimeOptimization", "No64BitChecks" }
		optimize "Full"

	configuration "Debug*"
		defines { "DEBUG", "_DEBUG" }
		flags { "MultiProcessorCompile", "Symbols", "No64BitChecks" }
		optimize "Debug"

	configuration "*Static"
		flags { "StaticRuntime" }

	project "iw4x"
		kind "SharedLib"
		language "C++"
		flags { "C++14" }
		files {
			"./src/**.rc",
			"./src/**.hpp",
			"./src/**.cpp",
			"./src/**.proto",
		}
		includedirs {
			"%{prj.location}/src",
			"./src"
		}
		resincludedirs {
			"$(ProjectDir)src" -- fix for VS IDE
		}

		-- Debug flags
		if _OPTIONS["ac-debug-detections"] then
			defines { "DEBUG_DETECTIONS" }
		end
		if _OPTIONS["ac-debug-load-library"] then
			defines { "DEBUG_LOAD_LIBRARY" }
		end
		if _OPTIONS["force-unit-tests"] then
			defines { "FORCE_UNIT_TESTS" }
		end
		if _OPTIONS["force-minidump-upload"] then
			defines { "FORCE_MINIDUMP_UPLOAD" }
		end
		if _OPTIONS["force-exception-handler"] then
			defines { "FORCE_EXCEPTION_HANDLER" }
		end
		if _OPTIONS["disable-bitmessage"] then
			defines { "DISABLE_BITMESSAGE" }
			removefiles {
				"./src/Components/Modules/BitMessage.*",
			}
		end

		-- Pre-compiled header
		pchheader "STDInclude.hpp" -- must be exactly same as used in #include directives
		pchsource "src/STDInclude.cpp" -- real path
		buildoptions { "/Zm200" }

		-- Dependency libraries
		if not _OPTIONS["disable-bitmessage"] then
			bitmrc.import()
		end
		fmt.import()
		json11.import()
		libtomcrypt.import()
		libtommath.import()
		mongoose.import()
		pdcurses.import()
		protobuf.import()
		winksignals.import()
		zlib.import()

		-- fix vpaths for protobuf sources
		vpaths
		{
			["*"] = { "./src/**" },
			["Proto/Generated"] = { "**.pb.*" }, -- meh.
		}

		-- Virtual paths
		if not _OPTIONS["no-new-structure"] then
			vpaths
			{
				["Headers/*"] = { "./src/**.hpp" },
				["Sources/*"] = { "./src/**.cpp" },
				["Resource/*"] = { "./src/**.rc" },
				["Proto/Definitions/*"] = { "./src/Proto/**.proto" },
				["Proto/Generated/*"] = { "**.pb.*" }, -- meh.
			}
		end

		vpaths
		{
			["Docs/*"] = { "**.txt","**.md" },
		}

		-- Pre-build
		prebuildcommands
		{
			"cd %{_MAIN_SCRIPT_DIR}",
			"tools\\premake5 generate-buildinfo",
		}

		-- Post-build
		if _OPTIONS["copy-to"] then
			saneCopyToPath = string.gsub(_OPTIONS["copy-to"] .. "\\", "\\\\", "\\")
			postbuildcommands {
				"if not exist \"" .. saneCopyToPath .. "\" mkdir \"" .. saneCopyToPath .. "\"",
			}

			if _OPTIONS["copy-pdb"] then
				postbuildcommands {
					"copy /y \"$(TargetDir)*.pdb\" \"" .. saneCopyToPath .. "\"",
				}
			end
			
			-- This has to be the last one, as otherwise VisualStudio will succeed building even if copying fails
			postbuildcommands {
				"copy /y \"$(TargetDir)*.dll\" \"" .. saneCopyToPath .. "\"",
			}
		end

		-- Specific configurations
		flags { "UndefinedIdentifiers", "ExtraWarnings" }

		configuration "Release*"
			flags {
				"FatalCompileWarnings",
				"FatalLinkWarnings",
			}
		configuration {}

		-- Generate source code from protobuf definitions
		filter "files:**.pb.*"
			flags {
				"NoPCH",
			}
			buildoptions {
				"/wd4100", -- "Unused formal parameter"
				"/wd4389", -- "Signed/Unsigned mismatch"
				"/wd6011", -- "Dereferencing NULL pointer"
				"/wd4125", -- "Decimal digit terminates octal escape sequence"
			}
			defines {
				"_SCL_SECURE_NO_WARNINGS",
			}
		filter {}
		rules { "ProtobufCompiler" }

		-- Workaround: Consume protobuf generated source files
		matches = os.matchfiles(path.join("src/Proto/**.proto"))
		for i, srcPath in ipairs(matches) do
			basename = path.getbasename(srcPath)
			files
			{
				string.format("%%{prj.location}/src/proto/%s.pb.h", basename),
				string.format("%%{prj.location}/src/proto/%s.pb.cc", basename),
			}
		end
		includedirs
		{
			"%{prj.location}/src/proto",
		}

	group "External dependencies"
		if not _OPTIONS["disable-bitmessage"] then
			bitmrc.project()
			libcryptopp.project()
			sqlite3.project()
		end
		fmt.project()
		json11.project()
		libtomcrypt.project()
		libtommath.project()
		mongoose.project()
		pdcurses.project()
		protobuf.project()
		winksignals.project()
		zlib.project()

rule "ProtobufCompiler"
	display "Protobuf compiler"
	location "./build"
	fileExtension ".proto"
	buildmessage "Compiling %(Identity) with protoc..."
	buildcommands {
		'@echo off',
		'path "$(SolutionDir)\\..\\tools"',
		'if not exist "$(ProjectDir)\\src\\proto" mkdir "$(ProjectDir)\\src\\proto"',
		'protoc --error_format=msvs -I=%(RelativeDir) --cpp_out=src\\proto %(Identity)',
	}
	buildoutputs {
		'$(ProjectDir)\\src\\proto\\%(Filename).pb.cc',
		'$(ProjectDir)\\src\\proto\\%(Filename).pb.h',
	}
