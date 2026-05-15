# task completion checks
- For repo-level config changes, verify the touched config syntax with the relevant tool when available.
- For dotfiles changes, confirm the target file path matches the stow package layout.
- When appropriate, re-run or cite the relevant setup command (`stow --no-folding <package>` or bootstrap) for applying changes on a machine.
- No universal automated test suite is defined in the repo root; verification is usually tool-specific and manual for configuration packages.
