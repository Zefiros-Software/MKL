function getICCVersion()
    versions = {
        "MKLROOT",
        "ICPP_COMPILER18", 
        "ICPP_COMPILER17", 
        "ICPP_COMPILER16", 
        "ICPP_COMPILER15"
    }
    for _, version in pairs(versions) do
        if os.getenv(version) ~= "" then
            return os.getenv(version)
        end
    end

    return nil
end

local function linkMKL(icpp)
    local libPrefix = "/"
    local libSuffix = ".lib"

    if os.ishost("linux") then
        libPrefix = "/lib"
        libSuffix = ""
    end
    
    local mkl64 = path.join(icpp, "mkl/lib/intel64/") .. libPrefix
    filter "architecture:not x86"
        if zpm.setting("blas95") then
            links( mkl64 .. "mkl_blas95_lp64" .. libSuffix )
        end
        if zpm.setting("core") then
            links( mkl64 .. "mkl_core" .. libSuffix )
        end
        if zpm.setting("intel") then
            links( mkl64 .. "mkl_intel_lp64" .. libSuffix )
        end
        if zpm.setting("lapack95") then
            links( mkl64 .. "mkl_lapack95_lp64" .. libSuffix )
        end
        if zpm.setting("sequential") then
            links( mkl64 .. "mkl_sequential" .. libSuffix )
        end
        if zpm.setting("tbb") then
            links( mkl64 .. "mkl_tbb_thread" .. libSuffix )
        end

    local mkl32 = path.join(icpp, "mkl/lib/ia32/") .. libPrefix
    filter "architecture:x86"
        if zpm.setting("blas95") then
            links( mkl32 .. "mkl_blas95" .. libSuffix )
        end
        if zpm.setting("core") then
            links( mkl32 .. "mkl_core" .. libSuffix )
        end
        if zpm.setting("intel") then
            links( mkl32 .. "mkl_intel_c" .. libSuffix )
        end
        if zpm.setting("lapack95") then
            links( mkl32 .. "mkl_lapack95" .. libSuffix )
        end
        if zpm.setting("sequential") then
            links( mkl32 .. "mkl_sequential" .. libSuffix )
        end
        if zpm.setting("tbb") then
            links( mkl32 .. "mkl_tbb_thread" .. libSuffix )
        end
end

project "MKL"
    kind "StaticLib"

    local icpp = getICCVersion()
    if icpp then
        zpm.export(function()
            includedirs(path.join(icpp, "mkl/include/"))    

            if os.ishost("linux") then
                linkMKL(icpp)
            end
        end)

        if not os.ishost("linux") then
            linkMKL(icpp)
        end

        filter {}
    else
        warningf("MKL not found on this computer, please check your libraries!")
    end
