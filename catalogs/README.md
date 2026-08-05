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

## Contributor workflow

Catalog changes are manually maintained and reviewed; MDTK does not scrape a
registry or automatically promote packages. For each proposed record:

1. Confirm from the package's authoritative documentation that it installs the
   listed executable names.
2. Explain popularity evidence, rank changes, aliases, and command collisions
   in the pull request. Never include credentials, private registry data, user
   queries, or local statistics files.
3. Keep the change focused on popular command-line tools, then run:

   ```sh
   conda activate mdtk
   make catalog-check
   ```

4. Review the compiled command count and byte count for every backend and run
   `make test` before merging.

`make catalog-check` compiles all four catalogs into a temporary directory in
fixed pip, npm, Cargo, conda order. It validates the complete input, ranking,
package and command syntax, deterministic collision handling, sorting, and the
per-backend capacity limit. The generated files are deleted; user XDG indexes
are not modified. The command is offline and never runs a package manager,
registry client, Git, curl, or any upload.

The complete five-index budget is 80 MiB: Homebrew 8 MiB, pip 16 MiB, npm
24 MiB, Cargo 12 MiB, and conda 20 MiB. Homebrew is built separately from its
complete executable metadata; this validation tool covers only the four
repository catalogs. `mdtk index build` and `mdtk index refresh` both rebuild
all five user indexes, while command lookup reads existing local files only.
Aggregate hit-rate events remain local and contain no command text; detailed
miss names are collected only after the user explicitly opts in. Catalog
expansion decisions therefore require a human review of voluntarily supplied
evidence, not automatic ingestion of private local telemetry.
