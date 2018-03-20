function getICCVersion()
    versions = {
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

project "MKL"
    kind "StaticLib"

    local icpp = getICCVersion()

    if icpp then
        zpm.export(function()
            includedirs(path.join(icpp, "mkl/include/"))    

            local mkl64 = path.join(icpp, "mkl/lib/intel64/")
            filter "architecture:not x86"
                if zpm.setting("blas95") then
                    links( mkl64 .. "/mkl_blas95_lp64.lib" )
                end
                if zpm.setting("core") then
                    links( mkl64 .. "/mkl_core.lib" )
                end
                if zpm.setting("intel") then
                    links( mkl64 .. "/mkl_intel_lp64.lib" )
                end
                if zpm.setting("lapack95") then
                    links( mkl64 .. "/mkl_lapack95_lp64.lib" )
                end
                if zpm.setting("rt") then
                    links( mkl64 .. "/mkl_rt.lib" )
                end
                if zpm.setting("sequential") then
                    links( mkl64 .. "/mkl_sequential.lib" )
                end
                if zpm.setting("tbb") then
                    links( mkl64 .. "/mkl_tbb_thread.lib" )
                end

            local mkl32 = path.join(icpp, "mkl/lib/ia32/")
            filter "architecture:x86"
                if zpm.setting("blas95") then
                    links( mkl32 .. "/mkl_blas95.lib" )
                end
                if zpm.setting("core") then
                    links( mkl32 .. "/mkl_core.lib" )
                end
                if zpm.setting("intel") then
                    links( mkl32 .. "/mkl_intel_c.lib" )
                end
                if zpm.setting("lapack95") then
                    links( mkl32 .. "/mkl_lapack95.lib" )
                end
                if zpm.setting("rt") then
                    links( mkl32 .. "/mkl_rt.lib" )
                end
                if zpm.setting("sequential") then
                    links( mkl32 .. "/mkl_sequential.lib" )
                end
                if zpm.setting("tbb") then
                    links( mkl32 .. "/mkl_tbb_thread.lib" )
                end

            filter {}
        end)
    else
        warningf("MKL not found on this computer, please check your libraries!")
    end
