# Contributing

Thanks for improving MoonBencode. Please keep changes focused, add regression
tests for behavior changes, and update the English and Chinese README files
when the public API changes.

Before opening a pull request, run:

```bash
moon check --deny-warn
moon fmt --check
moon info
moon build
moon test --deny-warn
moon test --deny-warn --target native
```

Do not commit `_build/`, `.mooncakes/`, generated secrets, or local toolchain
state. Public API changes should be reflected in the generated `pkg.generated.mbti`
files and documented with a changelog entry.
