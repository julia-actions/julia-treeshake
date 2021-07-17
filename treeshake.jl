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
    @error "Some direct dependencies were not used by test code" deps
    exit(1)
end
