# julia-treeshake Action

Run package tests or a given script to see if any project dependencies are unused via code coverage evaluation.

## Note

1) The information gathered by this action should be used with caution. The check is only as good as
the coverage of the package tests, or provided test script. Also consider that the setup of the CI
machine may impact coverage, with platform-guarded code usage hiding real code usage on other platforms.

2) If a dependency is only `using/import`-ed but has an `__init__()`, it will be marked as used.

## Usage

Julia needs to be installed before this action can run. This can easily be achieved with the [setup-julia](https://github.com/marketplace/actions/setup-julia-environment) action.

And example workflow that uses this action might look like this:

```yaml
name: Check for unused dependencies

on: [push, pull_request]

jobs:
  treeshake:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: julia-actions/setup-julia@v1
        with:
          version: 1
      - uses: julia-actions/julia-buildpkg@v1
      - uses: julia-actions/julia-treeshake@main
```

By default package tests will be run, but a custom script can be provided

```yaml
      - uses: julia-actions/julia-treeshake@main
        with:
          test_code: 'using Foo; Foo.bar()'
```

Or if you wanted to run tests manually, remember to enable at least `user` code coverage:
```yaml
      - uses: julia-actions/julia-treeshake@main
        with:
          test_code: 'import Pkg; Pkg.test(julia_args=["--code-coverage=user"])'
```

Or if you have already run the test code in a prior step with at least `user` code coverage:
```yaml
      - uses: julia-actions/julia-treeshake@main
        with:
          test_code: 'nothing'
```

You can add this workflow to your repository by placing it in a file called `treeshake.yml` in the folder `.github/workflows/`. [More info here](https://docs.github.com/en/actions/reference/workflow-syntax-for-github-actions).

### Prefixing the Julia command

In some packages, you may want to prefix the `julia` command with another command, e.g. for running tests of certain graphical libraries with `xvfb-run`.
In that case, you can add an input called `prefix` containing the command that will be inserted to your workflow:

```yaml
      - uses: julia-actions/julia-treeshake@main
        with:
          prefix: xvfb-run
```

If you only want to add this prefix on certain builds, you can [include additional values into a combination](https://docs.github.com/en/free-pro-team@latest/actions/reference/workflow-syntax-for-github-actions#example-including-additional-values-into-combinations) of your build matrix, e.g.:

```yaml
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, windows-latest, macOS-latest]
        version: ['1.0', '1', 'nightly']
        arch: [x64]
        include:
          - os: ubuntu-latest
            prefix: xvfb-run
    steps:
    # ...
      - uses: julia-actions/julia-runtest@v1
        with:
          prefix: ${{ matrix.prefix }}
    # ...
```

This will add the prefix `xvfb-run` to all builds where the `os` is `ubuntu-latest`.
