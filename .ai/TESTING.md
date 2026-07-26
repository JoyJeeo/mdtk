# Testing Rules

## What requires tests

- Every module requires tests.
- Every bug fix requires a regression test (a test that would have caught the bug).

## Coverage target

> 90%

## Test cases (every feature must cover)

- Success
- Failure (non-zero exit / expected error path)
- Edge cases (e.g. one-char input, Unicode, whitespace-only)
- Empty input
- Large input (e.g. a command index with thousands of entries)

## Framework & layout

- Framework: **shellspec**, running under zsh (pinned in `.shellspec`).
- Test files live under `tests/` and match `tests/**/*_spec.sh`.
- Global helpers: `tests/spec_helper.sh` (loaded via `--require spec_helper`).

## Running

```sh
conda activate mdtk
make test                                  # whole suite
make testone FILE=tests/bin/mdtk_spec.sh   # a single spec file
```

## Rules

- Specs test behavior (exit code, stdout, stderr), not internal helpers, unless the helper is the public contract of the module.
- Do not test unimplemented business logic — the stubs only need wiring smoke tests.
- Mock external tools (`brew`, `pip`, …) rather than depending on real installs.
