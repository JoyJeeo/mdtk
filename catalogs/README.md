# Popular CLI catalogs

These files are the reviewable, repository-maintained source for MDTK's pip,
npm, Cargo, and conda offline command indexes. They are shipped with each MDTK
release; compiling them never queries a registry or the network.

Each non-comment line has exactly three pipe-separated fields:

```text
rank|package|command command-alias ...
```

Ranks are decimal integers from 1 through 999999. Lower ranks win when more
than one package provides the same command; equal ranks use package-name byte
order so compilation remains deterministic. Package and command names must
pass the backend-specific compiler validation. Keep entries focused on popular
command-line tools, explain non-obvious changes in the pull request, and let
the compiler sort the generated index rather than manually sorting aliases.
