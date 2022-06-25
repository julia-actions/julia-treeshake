using Pkg

fail_direct = "--fail_unused_direct=yes" in ARGS
fail_indirect = "--fail_unused_indirect=yes" in ARGS

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

direct_deps = Pkg.Types.Context().env.project.deps
unused_direct_deps = String[]
for dep in direct_deps
    pkgname = first(dep)
    if haskey(found_dict, pkgname) && !found_dict[pkgname]
        push!(unused_direct_deps, pkgname)
    end
end

indirect_deps = [last(kv).name for kv in Pkg.Types.Context().env.manifest.deps]
unused_indirect_deps = String[]
for pkgname in indirect_deps
    if haskey(found_dict, pkgname) && !found_dict[pkgname]
        push!(unused_indirect_deps, pkgname)
    end
end

if length(unused_indirect_deps) == length(indirect_deps)
    @warn "No coverage files detected. Are you sure you ran code with at least coverage in `user` mode?"
end

@warn """Treeshaking Dependencies.
This information should be used with some caution:
- The check is only _at best_ as good as the coverage of the package tests, or provided test script.
- Consider that the setup of the CI machine may impact coverage, with platform-guarded code usage hiding real code usage on other platforms.
- Currently any `__init__()` calls within packages will mark them as used, even if they are only imported.
"""

if isempty(unused_direct_deps) && isempty(unused_indirect_deps)
    @info "All $(length(direct_deps)) direct and $(length(indirect_deps)) indirect dependencies were used"
else
    if !isempty(unused_direct_deps)
        @info """$(length(unused_direct_deps)) of $(length(direct_deps)) direct dependencies were not used by the test code: \n  $(join(sort(unused_direct_deps), "\n  "))"""
    end
    if !isempty(unused_indirect_deps)
        @info """$(length(unused_indirect_deps)) of $(length(indirect_deps)) indirect dependencies were not used by the test code: \n  $(join(sort(unused_indirect_deps), "\n  "))"""
    end
    fail_direct && !isempty(unused_direct_deps) && exit(1)
    fail_indirect && !isempty(unused_indirect_deps) && exit(1)
end
