using Pkg

function has_cov(pkg_dir)
    for (root, dirs, files) in walkdir(pkg_dir)
        if any(endswith(".cov"), files)
            return true
        end
    end
    return false
end

depot_packages = filter(isdir, readdir(joinpath(Base.DEPOT_PATH[1], "packages"), join = true))

found_dict = Dict{String,Bool}()
for dir in depot_packages
    pkgname = splitpath(dir)[end]
    try
        found_dict[pkgname] = has_cov(dir)
    catch ex
        @error "Could not search coverage for $dir" exception = (ex, catch_backtrace())
    end
end

deps = copy(Pkg.Types.Context().env.project.deps)
for dep in deps
    pkgname = first(dep)
    if !haskey(found_dict, pkgname) || found_dict[pkgname]
        delete!(deps, first(dep))
    end
end

if !isempty(deps)
    @error "Some direct dependencies were not used by the test code" deps

    @warn """This information should be used with caution.
    The check is only _at best_ as good as the coverage of the package tests, or provided test script.
    Also consider that the setup of the CI machine may impact coverage, with platform-guarded code
    usage hiding real code usage on other platforms.
    """
    exit(1)
end
