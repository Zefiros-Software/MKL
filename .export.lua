local function wrapEnv(var)
    if os.ishost("windows") then
        return "%" .. var .. "%"
    else
        return "${" .. var .. "}"
    end
end

function getICCVersion()
    versions = {
        "MKLROOT",
        "ICPP_COMPILER18", 
        "ICPP_COMPILER17", 
        "ICPP_COMPILER16", 
        "ICPP_COMPILER15"
    }
    for _, version in pairs(versions) do
        local mklRoot = os.getenv(version)
        local tbbRoot = mklRoot
        if mklRoot ~= "" and mklRoot ~= nil then
            if version ~= "MKLROOT" then
                mklRoot = path.join(wrapEnv(version), "mkl")
                tbbRoot = path.join(wrapEnv(version), "tbb")
            else
                mklRoot = wrapEnv(version)
                tbbRoot = wrapEnv("TBBROOT")
            end

            return mklRoot, tbbRoot
        end
    end

    return nil, nil
end

local mklBackends = {
    sequential = "mkl_sequential",
    tbb = "mkl_tbb_thread"
}

-- Safe way to get the backend, with fallback to sequential
local function getMKLBackend()
    local backend = zpm.setting("backend")

    if backend ~= nil and mklBackends[backend] ~= nil then
        backend = mklBackends[backend]
    else
        if backend == nil then
            warningf("Using fallback backend 'sequential' for MKL.")
        else
            local warn = "Backend '" .. backend .. "' is not valid for MKL. Valid backends are:"
            for b, _ in pairs(mklBackends) do
                warn = warn .. " '" .. b .. "'"
            end

            warningf(warn .. ". Using fallback 'sequential'.")
        end

        backend = mklBackends["sequential"]
    end

    return backend
end

-- On linux, we add the mklRoot as libdir
local function mklLib( mklRoot, mklLib )
    if os.ishost("linux") then
        return mklLib
    else
        return path.join(mklRoot, mklLib)
    end
end

-- On linux, MKL libraries should be grouped when linking.
local function linkGroupedLinks(linkGroup, mklRoot)
    if os.ishost("linux") then
        local groupedLinks = "-Wl,--start-group"

        for _, libEntry in pairs(linkGroup) do
            groupedLinks = groupedLinks .. " -l" .. libEntry
        end
        groupedLinks = groupedLinks .. " -Wl,--end-group"

        libdirs( mklRoot )
        linkoptions(groupedLinks)
    else
        links( linkGroup )
    end
end

local function linkMKL(mklRoot, tbbRoot, backend)
    local mkl64 = path.join(mklRoot, "lib/intel64/")
    local tbb64 = nil
    local tbb32 = nil

    if backend == "mkl_tbb_thread" then
        if tbbRoot == nil then
            errorf("TBB root is not set, but tbb backend was requested. Please source the tbbvars.sh correctly.")
        end
        tbb64 = path.join(tbbRoot, "lib/intel64/")
        tbb32 = path.join(tbbRoot, "lib/ia32/")
    end

    filter "architecture:not x86"
        local linkGroup = {}
        
        table.insert( linkGroup, mklLib( mkl64, backend) )
        
        if tbb64 ~= nil then
            table.insert( linkGroup, mklLib( tbb64, "vc14/tbb") )
        end

        if zpm.setting("intel") then
            table.insert( linkGroup, mklLib( mkl64, "mkl_intel_lp64" ) )
        end
        if zpm.setting("core") then
            table.insert( linkGroup, mklLib( mkl64, "mkl_core" ) )
        end
        if zpm.setting("blas95") then
            table.insert( linkGroup, mklLib( mkl64, "mkl_blas95_lp64" ) )
        end
        if zpm.setting("lapack95") then
            table.insert( linkGroup, mklLib( mkl64, "mkl_lapack95_lp64" ) )
        end

        linkGroupedLinks(linkGroup, mkl64)

    local mkl32 = path.join(mklRoot, "lib/ia32/")
    filter "architecture:x86"
        local linkGroup = {}
        
        table.insert( linkGroup, mklLib( mkl32, backend) )
    
        if tbb32 ~= nil then
            table.insert( linkGroup, mklLib( tbb32, "vc14/tbb") )
        end
            
        if zpm.setting("intel") then
            if os.ishost("windows") then
                table.insert( linkGroup, mklLib( mkl32, "mkl_intel_c" ) )
            else
                table.insert( linkGroup, mklLib( mkl32, "mkl_intel" ) )
            end
        end
        if zpm.setting("core") then
            table.insert( linkGroup, mklLib( mkl32, "mkl_core" ) )
        end
        if zpm.setting("blas95") then
            table.insert( linkGroup, mklLib( mkl32, "mkl_blas95" ) )
        end
        if zpm.setting("lapack95") then
            table.insert( linkGroup, mklLib( mkl32, "mkl_lapack95" ) )
        end


        linkGroupedLinks(linkGroup, mkl32)

    filter {}
end

local function relinkTBB(tbbRoot, backend)
    local tbb64 = nil
    local tbb32 = nil

    if backend == "mkl_tbb_thread" then
        if tbbRoot == nil then
            errorf("TBB root is not set, but tbb backend was requested. Please source the tbbvars.sh correctly.")
        end
        tbb64 = path.join(tbbRoot, "lib/intel64/")
        tbb32 = path.join(tbbRoot, "lib/ia32/")
    end

    if tbb64 ~= nil then
        filter "architecture:not x86"
            links( mklLib( tbb64, "vc14/tbb") )
    end

    local mkl32 = path.join(mklRoot, "lib/ia32/")
    if tbb32 ~= nil then
        filter "architecture:x86"
            links( mklLib( tbb32, "vc14/tbb") )
    end

    filter {}
end

project "MKL"
    kind "StaticLib"

    local mklRoot, tbbRoot = getICCVersion()

    if mklRoot then
        local backend = getMKLBackend()

        zpm.export(function()
            includedirs(path.join(mklRoot, "include/"))

            if os.ishost("linux") then
                linkMKL(mklRoot, tbbRoot, backend)
            end

            relinkTBB(tbbRoot, backend)
        end)

        if not os.ishost("linux") then
            linkMKL(mklRoot, tbbRoot, backend)
        end
    else
        warningf("MKL not found on this computer, please check your libraries!")
    end
